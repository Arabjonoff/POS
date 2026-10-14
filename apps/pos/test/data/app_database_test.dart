import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/sqlite.dart';

void main() {
  group('settings', () {
    late AppDatabase db;

    setUp(() => db = openTestDatabase());
    tearDown(() => db.close());

    test('settings can be written, read and overwritten', () async {
      expect(await db.readSetting('locale'), isNull);
      await db.writeSetting('locale', 'uz');
      expect(await db.readSetting('locale'), 'uz');
      await db.writeSetting('locale', 'ru');
      expect(await db.readSetting('locale'), 'ru');
    });
  });

  group('file database (as on the device)', () {
    late Directory dir;

    setUp(() {
      setUpTestSqlite();
      dir = Directory.systemTemp.createTempSync('pos_db_test');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    AppDatabase open() =>
        AppDatabase(NativeDatabase(File('${dir.path}/pos.sqlite')));

    Future<Object?> pragma(AppDatabase db, String name) async =>
        (await db.customSelect('PRAGMA $name').getSingle()).data.values.first;

    test('WAL, synchronous=FULL and foreign keys are on', () async {
      final db = open();
      addTearDown(db.close);
      expect(await pragma(db, 'journal_mode'), 'wal');
      // 2 = FULL.
      expect(await pragma(db, 'synchronous'), 2);
      expect(await pragma(db, 'foreign_keys'), 1);
    });

    test('committed data survives reopening', () async {
      final db = open();
      await db
          .into(db.outboxEvents)
          .insert(
            OutboxEventsCompanion.insert(
              id: 'e1',
              type: 'shift.opened',
              payload: '{}',
              createdAt: DateTime.utc(2026),
            ),
          );
      await db.close();

      final reopened = open();
      addTearDown(reopened.close);
      final event = await reopened.select(reopened.outboxEvents).getSingle();
      expect(event.id, 'e1');
      expect(event.attempts, 0);
      expect(event.createdAt.isAtSameMomentAs(DateTime.utc(2026)), isTrue);
    });
  });

  group('schema rules', () {
    late AppDatabase db;
    final t = DateTime.utc(2026, 10, 14);

    setUp(() => db = openTestDatabase());
    tearDown(() => db.close());

    ShiftsCompanion shift(String id, {DateTime? closedAt}) =>
        ShiftsCompanion.insert(
          id: id,
          storeId: 's',
          deviceId: 'device-1',
          openedBy: 'u',
          openedAt: t,
          openingCashTiyin: 0,
          closedAt: Value(closedAt),
        );

    test('only one open shift per device', () async {
      await db.into(db.shifts).insert(shift('a', closedAt: t));
      await db.into(db.shifts).insert(shift('b'));
      await expectLater(
        db.into(db.shifts).insert(shift('c')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('sale items cannot point to a missing sale', () async {
      await expectLater(
        db
            .into(db.saleItems)
            .insert(
              SaleItemsCompanion.insert(
                id: 'i',
                saleId: 'missing',
                position: 0,
                productId: 'p',
                nameSnapshot: 'n',
                qtyMilli: 1000,
                priceTiyin: 1,
                costTiyin: 1,
                discountTiyin: 0,
                totalTiyin: 1,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('receipt number is unique', () async {
      await db.into(db.shifts).insert(shift('a'));
      SalesCompanion sale(String id) => SalesCompanion.insert(
        id: id,
        shiftId: 'a',
        cashierId: 'u',
        number: 'D1-000001',
        subtotalTiyin: 0,
        discountTiyin: 0,
        totalTiyin: 0,
        soldAt: t,
      );
      await db.into(db.sales).insert(sale('s1'));
      await expectLater(
        db.into(db.sales).insert(sale('s2')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('money and quantities keep full 64-bit integers', () async {
      // 2^53 + 1 — double'da yo'qoladi. Kassa faqat native (JS emas).
      // ignore: avoid_js_rounded_ints
      const big = 9007199254740993;
      await db
          .into(db.productStock)
          .insert(
            ProductStockCompanion.insert(
              productId: 'p',
              storeId: 's',
              qtyMilli: big,
              updatedAt: t,
            ),
          );
      expect((await db.select(db.productStock).getSingle()).qtyMilli, big);
    });

    test('sync state defaults', () async {
      await db.into(db.syncState).insert(const SyncStateCompanion());
      final state = await db.select(db.syncState).getSingle();
      expect(state.id, 1);
      expect(state.pullCursor, '0');
      expect(state.serverTimeOffsetMs, 0);
    });
  });
}
