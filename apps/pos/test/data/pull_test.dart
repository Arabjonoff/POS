import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_api_client/pos_api_client.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/pull.dart';

import '../helpers/fake_server.dart';
import '../helpers/sqlite.dart';

final DateTime now = DateTime.utc(2026, 10, 14, 10);

Map<String, Object?> page(
  List<Map<String, Object?>> changes, {
  String next = '100:1',
  bool hasMore = false,
}) => {
  'changes': changes,
  'next_cursor': next,
  'has_more': hasMore,
  'subscription': {
    'status': 'active',
    'paid_until': '2026-11-30',
    'days_left': 47,
    'offline_days': 7,
  },
  'server_time': '2026-10-14T10:00:30Z',
};

Map<String, Object?> up(String entity, String id, Map<String, Object?> data) =>
    {'entity': entity, 'op': 'upsert', 'id': id, 'data': data};

Map<String, Object?> del(String entity, String id) => {
  'entity': entity,
  'op': 'delete',
  'id': id,
  'data': null,
};

Map<String, Object?> product({
  String id = 'p1',
  String name = 'Non',
  List<String> barcodes = const ['4780001000012', '200'],
  int price = 500000,
}) => {
  'id': id,
  'name': name,
  'category': 'c1',
  'unit': 'u1',
  'sell_price_tiyin': price,
  'cost_price_tiyin': 400000,
  'is_weighted': false,
  'plu_code': null,
  'min_stock_milli': 5000,
  'ikpu_code': '',
  'quick_button': true,
  'is_active': true,
  'barcodes': barcodes,
  'markup_bp': 2500,
  'created_at': '2026-10-01T00:00:00Z',
  'updated_at': '2026-10-02T00:00:00Z',
};

void main() {
  late AppDatabase db;
  late PullApplier applier;

  setUp(() {
    db = openTestDatabase();
    applier = PullApplier(db, now: () => now);
  });
  tearDown(() => db.close());

  Future<void> apply(Map<String, Object?> json) =>
      applier.apply(PullResponse.fromJson(json));

  test('applies every entity type', () async {
    await apply(
      page([
        up('unit', 'u1', {
          'id': 'u1',
          'code': 'pcs',
          'name': '',
          'is_fractional': false,
        }),
        up('category', 'c1', {
          'id': 'c1',
          'name': 'Non',
          'parent': null,
          'sort': 2,
          'color': 'green',
        }),
        up('product', 'p1', product()),
        up('supplier', 's1', {
          'id': 's1',
          'name': 'Ulgurji',
          'phone': '',
          'note': '',
        }),
        up('customer', 'k1', {
          'id': 'k1',
          'full_name': 'Olim aka',
          'phone': '+998901112233',
          'note': '',
          'debt_limit_tiyin': null,
          'balance_tiyin': 1500000,
          'created_at': '2026-10-01T00:00:00Z',
          'updated_at': '2026-10-02T00:00:00Z',
        }),
        up('user', 'us1', {
          'id': 'us1',
          'phone': null,
          'full_name': 'Aziza',
          'role': 'cashier',
          'is_active': true,
          'pin_hash': r'pbkdf2_sha256$120000$s$h',
        }),
        up('store', 'st1', {
          'id': 'st1',
          'name': "Baraka do'koni",
          'address': 'Chilonzor',
          'phone': '',
          'receipt_header': 'Xush kelibsiz',
          'receipt_footer': 'Rahmat',
        }),
        up('debt_entry', 'd1', {
          'id': 'd1',
          'customer': 'k1',
          'amount_tiyin': 1500000,
          'type': 'sale',
          'method': '',
          'sale_id': 'sale-1',
          'note': '',
          'created_by': 'us1',
          'at': '2026-10-02T08:00:00Z',
        }),
        up('stock', 'p1', {
          'product': 'p1',
          'store': 'st1',
          'qty_milli': 24000,
          'updated_at': '2026-10-02T09:00:00Z',
        }),
      ]),
    );

    expect((await db.select(db.units).getSingle()).code, 'pcs');
    expect((await db.select(db.categories).getSingle()).color, 'green');
    final p = await db.select(db.products).getSingle();
    expect(p.sellPriceTiyin, 500000);
    expect(p.quickButton, isTrue);
    expect(p.ikpuCode, isNull);
    expect(p.searchKey, 'non');
    final barcodes = await db.select(db.productBarcodes).get();
    expect(
      {for (final b in barcodes) b.barcode: b.isPrimary},
      {'4780001000012': true, '200': false},
    );
    expect((await db.select(db.suppliers).getSingle()).name, 'Ulgurji');
    expect((await db.select(db.customers).getSingle()).balanceTiyin, 1500000);
    final user = await db.select(db.staffUsers).getSingle();
    expect(user.pinHash, startsWith('pbkdf2'));
    expect(user.phone, isNull);
    expect((await db.select(db.stores).getSingle()).receiptFooter, 'Rahmat');
    final debt = await db.select(db.debtEntries).getSingle();
    expect(debt.byUserId, 'us1');
    expect(debt.method, isNull);
    expect((await db.select(db.productStock).getSingle()).qtyMilli, 24000);

    final state = await db.select(db.syncState).getSingle();
    expect(state.pullCursor, '100:1');
    expect(state.lastPullAt!.isAtSameMomentAs(now), isTrue);
    expect(state.serverTimeOffsetMs, 30000);
    expect(
      state.offlineGraceUntil!.isAtSameMomentAs(
        DateTime.utc(2026, 10, 21, 10, 0, 30),
      ),
      isTrue,
    );
    expect(
      (jsonDecode(state.subscriptionJson!) as Map)['status'],
      'active',
    );
  });

  test('server wins: upsert overwrites, barcodes are replaced', () async {
    await apply(page([up('product', 'p1', product())]));
    await apply(
      page([
        up(
          'product',
          'p1',
          product(name: 'Non yangi', price: 600000, barcodes: ['999']),
        ),
      ]),
    );
    final p = await db.select(db.products).getSingle();
    expect(p.name, 'Non yangi');
    expect(p.sellPriceTiyin, 600000);
    final barcodes = await db.select(db.productBarcodes).get();
    expect(barcodes.map((b) => b.barcode), ['999']);
  });

  test('a barcode moved to another product follows it', () async {
    await apply(
      page([
        up('product', 'p1', product(barcodes: ['111'])),
      ]),
    );
    await apply(
      page([
        up('product', 'p2', product(id: 'p2', barcodes: ['111'])),
      ]),
    );
    final b = await db.select(db.productBarcodes).getSingle();
    expect(b.productId, 'p2');
  });

  test('delete is soft for catalog, hard for the rest', () async {
    await apply(
      page([
        up('product', 'p1', product()),
        up('user', 'us1', {
          'id': 'us1',
          'full_name': 'A',
          'role': 'cashier',
          'is_active': true,
          'pin_hash': '',
        }),
      ]),
    );
    await apply(page([del('product', 'p1'), del('user', 'us1')]));
    final p = await db.select(db.products).getSingle();
    expect(p.deletedAt, isNotNull);
    expect(p.isActive, isFalse);
    expect(await db.select(db.productBarcodes).get(), isEmpty);
    expect(await db.select(db.staffUsers).get(), isEmpty);
  });

  test('unknown entities are ignored (new server, old app)', () async {
    await apply(
      page([
        up('loyalty_card', 'x', {'id': 'x'}),
        del('unknown', 'y'),
      ]),
    );
    expect((await db.select(db.syncState).getSingle()).pullCursor, '100:1');
  });

  test('a failing page leaves nothing half-applied', () async {
    // O'zgarishlar yozilgandan keyin, kursor saqlanayotganda xato.
    final failing = PullApplier(db, now: () => throw StateError('crash'));
    await expectLater(
      failing.apply(
        PullResponse.fromJson(
          page([
            up('unit', 'u1', {
              'id': 'u1',
              'code': 'pcs',
              'name': '',
              'is_fractional': false,
            }),
            up('product', 'p1', product()),
          ]),
        ),
      ),
      throwsStateError,
    );
    expect(await db.select(db.units).get(), isEmpty);
    expect(await db.select(db.products).get(), isEmpty);
    expect(await db.select(db.productBarcodes).get(), isEmpty);
    expect(await db.select(db.syncState).get(), isEmpty);
  });

  test('SyncPuller follows has_more and the cursor', () async {
    final server = FakeServer()
      ..on('GET /api/v1/sync/pull/', (r) {
        final cursor = r.query['cursor'];
        return switch (cursor) {
          '0' => (
            200,
            page([up('product', 'p1', product())], next: '1:1', hasMore: true),
          ),
          '1:1' => (
            200,
            page([
              up('product', 'p2', product(id: 'p2', barcodes: ['2'])),
            ], next: '1:2'),
          ),
          _ => (400, apiError('bad_cursor')),
        };
      });
    final progress = <int>[];
    final applied = await SyncPuller(
      db,
      deviceApi(server.dio, 'dev_token'),
      applier: applier,
    ).pullAll(onProgress: progress.add);

    expect(applied, 2);
    expect(progress, [1, 2]);
    expect(server.requests.map((r) => r.query['cursor']), ['0', '1:1']);
    expect(server.requests.first.authorization, 'Device dev_token');
    expect((await db.select(db.syncState).getSingle()).pullCursor, '1:2');
    expect(await db.select(db.products).get(), hasLength(2));
  });

  test('network failure keeps the last applied cursor', () async {
    var calls = 0;
    final server = FakeServer()
      ..on('GET /api/v1/sync/pull/', (r) {
        calls++;
        if (calls == 1) {
          return (
            200,
            page([up('product', 'p1', product())], next: '1:1', hasMore: true),
          );
        }
        return null;
      });
    final puller = SyncPuller(db, deviceApi(server.dio, 't'), applier: applier);
    await expectLater(puller.pullAll(), throwsA(anything));
    expect((await db.select(db.syncState).getSingle()).pullCursor, '1:1');
    expect(ApiFailure.from(Exception()).kind, ApiFailureKind.server);
  });
}
