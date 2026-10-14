import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/app/sync/sync_runner.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/data/sync/push.dart';
import 'package:pos_app/data/sync/sync_engine.dart';

import '../helpers/fake_sync_server.dart';
import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late FakeSyncServer server;
  late DateTime now;
  late SyncEngine engine;
  var eventIds = 0;

  setUp(() async {
    db = openTestDatabase();
    server = FakeSyncServer();
    now = DateTime.utc(2026, 10, 14, 10);
    eventIds = 0;
    engine = SyncEngine(
      db,
      () async => deviceApi(server.http.dio, 'dev_token'),
      now: () => now,
    );
    await db
        .into(db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: 'shift-1',
            storeId: 'store-1',
            deviceId: 'device-1',
            openedBy: 'u',
            openedAt: now,
            openingCashTiyin: 0,
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> addEvent({String type = 'cash.moved', DateTime? at}) =>
      db.enqueueEvent(
        id: 'e${(++eventIds).toString().padLeft(4, '0')}',
        type: type,
        payload: {'n': eventIds},
        createdAt: at ?? now.add(Duration(milliseconds: eventIds)),
      );

  Future<List<OutboxEvent>> outbox() => (db.select(
    db.outboxEvents,
  )..orderBy([(e) => OrderingTerm(expression: e.createdAt)])).get();

  Future<void> sellOffline(int count) async {
    final writer = SaleWriter(db, deviceNumber: 1, now: () => now);
    for (var i = 0; i < count; i++) {
      now = now.add(const Duration(seconds: 1));
      await writer.complete(
        const CompletedSaleInput(
          shiftId: 'shift-1',
          cashierId: 'u',
          lines: [
            SaleLineInput(
              productId: 'bread',
              name: 'Non',
              qtyMilli: 1000,
              priceTiyin: 500000,
              costTiyin: 400000,
            ),
          ],
          payments: [SalePaymentInput.card(amountTiyin: 500000)],
        ),
      );
    }
  }

  group('push', () {
    test('sends in created_at order and marks results', () async {
      await addEvent(at: now.add(const Duration(seconds: 2)));
      await addEvent(at: now.add(const Duration(seconds: 1)));
      await addEvent(type: 'sale.completed');
      server.rejectTypes.add('sale.completed');

      final report = await engine.syncOnce(pull: false);
      expect(report.health, SyncHealth.online);
      expect(report.pushed, 2);
      expect(report.rejected, 1);

      final sent = server.http.requests.single.body! as Map;
      final ids = (sent['events'] as List).map((e) => (e as Map)['id']);
      expect(ids, ['e0003', 'e0002', 'e0001']);
      final first = (sent['events'] as List).first as Map;
      expect(first['created_at'], endsWith('Z'));

      final rows = {for (final e in await outbox()) e.id: e};
      expect(rows['e0001']!.status, OutboxStatus.sent);
      expect(rows['e0001']!.sentAt, isNotNull);
      expect(rows['e0003']!.status, OutboxStatus.rejected);
      expect(rows['e0003']!.lastError, 'invalid_sale: bad');

      // Rad etilgan qayta yuborilmaydi.
      await engine.syncOnce(pull: false);
      expect(server.http.requests, hasLength(1));
    });

    test('batches of 100', () async {
      for (var i = 0; i < 250; i++) {
        await addEvent();
      }
      final report = await engine.syncOnce(pull: false);
      expect(report.pushed, 250);
      expect(server.batchSizes, [100, 100, 50]);
    });

    test('backoff grows 5 s → … → 5 min', () {
      expect(OutboxPusher.backoff(1), const Duration(seconds: 5));
      expect(OutboxPusher.backoff(2), const Duration(seconds: 10));
      expect(OutboxPusher.backoff(3), const Duration(seconds: 20));
      expect(OutboxPusher.backoff(6), const Duration(seconds: 160));
      expect(OutboxPusher.backoff(7), const Duration(minutes: 5));
      expect(OutboxPusher.backoff(20), const Duration(minutes: 5));
    });

    test('network failure: wait, keep order, resend the same ids', () async {
      await addEvent();
      await addEvent();
      server.offline = true;

      expect((await engine.syncOnce(pull: false)).health, SyncHealth.offline);
      var rows = await outbox();
      expect(rows.every((e) => e.attempts == 1), isTrue);
      expect(rows.first.nextAttemptAt, now.add(const Duration(seconds: 5)));

      // Yangi hodisa eskilaridan oldin ketmaydi; kutish vaqti kelmaguncha
      // hech narsa yuborilmaydi.
      await addEvent();
      server.offline = false;
      await engine.syncOnce(pull: false);
      expect(server.batchSizes, isEmpty);

      now = now.add(const Duration(seconds: 6));
      await engine.syncOnce(pull: false);
      expect(server.applied.keys, ['e0001', 'e0002', 'e0003']);
      rows = await outbox();
      expect(rows.every((e) => e.status == OutboxStatus.sent), isTrue);
    });

    test('second failure doubles the wait', () async {
      await addEvent();
      server.offline = true;
      await engine.syncOnce(pull: false);
      now = now.add(const Duration(seconds: 6));
      await engine.syncOnce(pull: false);
      final row = (await outbox()).single;
      expect(row.attempts, 2);
      expect(row.nextAttemptAt, now.add(const Duration(seconds: 10)));
    });
  });

  group('sync.md client acceptance', () {
    test(
      '5: 500 sales offline, then online → exactly 500 on the server',
      () async {
        server.offline = true;
        await sellOffline(500);
        expect((await engine.syncOnce()).health, SyncHealth.offline);
        expect(server.applied, isEmpty);

        server.offline = false;
        now = now.add(const Duration(minutes: 10));
        final report = await engine.syncOnce();
        expect(report.health, SyncHealth.online);
        expect(report.pushed, 500);
        expect(server.applied.length, 500);
        expect(server.applied.values.toSet(), {OutboxEventType.saleCompleted});
        expect(
          (await outbox()).where((e) => e.status != OutboxStatus.sent),
          isEmpty,
        );
      },
    );

    test('6: connection drops mid-push → no duplicates on retry', () async {
      await sellOffline(150);
      // 1-paket serverda qo'llanadi, lekin javob yo'qoladi.
      server.loseNextResponse = true;
      expect((await engine.syncOnce()).health, SyncHealth.offline);
      expect(server.applied.length, 100);
      expect(
        (await outbox()).where((e) => e.status == OutboxStatus.sent),
        isEmpty,
      );

      now = now.add(const Duration(minutes: 1));
      await engine.syncOnce();
      // O'sha 100 ta — duplicate (yangi yozuv emas), qolgan 50 — applied.
      expect(server.applied.length, 150);
      expect(server.batchSizes, [100, 100, 50]);
      expect(
        (await outbox()).every((e) => e.status == OutboxStatus.sent),
        isTrue,
      );
    });

    test('8: readonly subscription stops sales, sync keeps working', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(salesBlockProvider, (_, _) {});
      addTearDown(sub.close);

      server.subscriptionStatus = 'readonly';
      await addEvent();
      final report = await engine.syncOnce();
      expect(report.health, SyncHealth.online);
      expect(report.pushed, 1);
      await pumpEventQueue();
      expect(container.read(salesBlockProvider), SalesBlock.readonly);
      expect(container.read(salesAllowedProvider), isFalse);

      server.subscriptionStatus = 'active';
      await engine.syncOnce();
      await pumpEventQueue();
      expect(container.read(salesBlockProvider), SalesBlock.none);
    });
  });

  group('health', () {
    test('device blocked (403) is remembered until the next success', () async {
      server.forcedError = (
        403,
        {
          'error': {
            'code': 'device_blocked',
            'message': '',
            'details': <String, Object?>{},
          },
        },
      );
      expect(
        (await engine.syncOnce()).health,
        SyncHealth.deviceBlocked,
      );
      expect(await db.readSetting(SyncEngine.deviceBlockedKey), '1');
      server.forcedError = null;
      await engine.syncOnce();
      expect(await db.readSetting(SyncEngine.deviceBlockedKey), '0');
    });

    test('invalid token (401) and missing token', () async {
      server.forcedError = (
        401,
        {
          'error': {'code': 'not_authenticated'},
        },
      );
      expect((await engine.syncOnce()).health, SyncHealth.unauthorized);
      final noToken = SyncEngine(db, () async => null);
      expect((await noToken.syncOnce()).health, SyncHealth.unauthorized);
    });

    test('pull runs after push and saves the cursor', () async {
      await addEvent();
      await engine.syncOnce();
      final paths = server.http.requests.map((r) => r.path);
      expect(paths, ['/api/v1/sync/push/', '/api/v1/sync/pull/']);
      expect((await db.select(db.syncState).getSingle()).pullCursor, 'c1');
    });
  });

  group('sales gate', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
      );
    });
    tearDown(() => container.dispose());

    Future<SalesBlock> block() async {
      final sub = container.listen(salesBlockProvider, (_, _) {});
      await pumpEventQueue();
      final value = container.read(salesBlockProvider);
      sub.close();
      return value;
    }

    test('offline longer than offline_days stops sales', () async {
      server
        ..offlineDays = 7
        ..serverTime = '2026-10-14T10:00:00Z';
      await engine.syncOnce();
      expect(await block(), SalesBlock.none);

      now = DateTime.utc(2026, 10, 21, 9, 59);
      container.invalidate(salesBlockProvider);
      expect(await block(), SalesBlock.none);

      now = DateTime.utc(2026, 10, 21, 10, 1);
      container.invalidate(salesBlockProvider);
      expect(await block(), SalesBlock.offlineTooLong);
    });

    test('device clock behind the server is corrected', () async {
      // Qurilma soati 2 kun orqada: server 16-oktabr, qurilma 14-oktabr.
      server
        ..serverTime = '2026-10-16T10:00:00Z'
        ..offlineDays = 1;
      await engine.syncOnce();
      now = DateTime.utc(2026, 10, 15, 11);
      container.invalidate(salesBlockProvider);
      // Server bo'yicha 17-oktabr 11:00 — muddat (17-okt 10:00) o'tgan.
      expect(await block(), SalesBlock.offlineTooLong);

      final sub = container.listen(clockSkewProvider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(clockSkewProvider), isTrue);
      sub.close();
    });

    test('blocked tenant and blocked device', () async {
      server.subscriptionStatus = 'blocked';
      await engine.syncOnce();
      expect(await block(), SalesBlock.blocked);

      await db.writeSetting(SyncEngine.deviceBlockedKey, '1');
      container.invalidate(salesBlockProvider);
      expect(await block(), SalesBlock.deviceBlocked);
    });

    test('rejected events are counted for the status bar', () async {
      server.rejectTypes.add('cash.moved');
      await addEvent();
      await addEvent();
      await engine.syncOnce(pull: false);
      final sub = container.listen(rejectedEventsProvider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(rejectedEventsProvider).value, 2);
      sub.close();
    });
  });

  test('connection status follows the last sync', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(connectionStatusProvider), ConnectionStatus.unknown);
    container
        .read(syncStatusProvider.notifier)
        .set(const SyncStatus(health: SyncHealth.offline));
    expect(container.read(connectionStatusProvider), ConnectionStatus.offline);
    container
        .read(syncStatusProvider.notifier)
        .set(const SyncStatus(health: SyncHealth.online));
    expect(container.read(connectionStatusProvider), ConnectionStatus.online);
  });
}
