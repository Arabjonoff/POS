import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sales/remote_sale.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/fake_server.dart';
import '../helpers/remote_sale_fixture.dart';
import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late FakeServer server;
  late ProviderContainer container;
  (int, Object?)? Function() reply = () => (200, remoteSaleJson());

  setUp(() async {
    db = openTestDatabase();
    await seedCatalog(db);
    server = FakeServer()..on('GET /api/v1/sync/sales/', (_) => reply());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        dioFactoryProvider.overrideWithValue(server.dio),
        deviceTokenStoreProvider.overrideWithValue(
          MemoryDeviceTokenStore('dev_token'),
        ),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<RemoteSaleResult> find(String number) =>
      container.read(remoteSalesProvider).find(number);

  test('found: device token, upper-case number, refundable lines', () async {
    final result = await find(' d2-000007 ');
    final request = server.requests.single;
    expect(request.authorization, 'Device dev_token');
    expect(request.query['number'], 'D2-000007');
    final sale = (result as RemoteSaleFound).sale;
    expect(sale.sale.deviceNumber, 2);
    expect(sale.status, 'partially_refunded');
    final item = sale.refundable.items.single;
    expect(item.unit, 'pcs');
    expect(item.remainingQtyMilli, 2000);
    expect(sale.refunds.single.reason, 'Yaroqsiz');
  });

  test('a refund made here, not yet on the server, is counted', () async {
    await db
        .into(db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: 'shift-1',
            storeId: 'store-1',
            deviceId: 'device-1',
            openedBy: 'cashier-1',
            openedAt: DateTime.utc(2026, 10, 14, 3),
            openingCashTiyin: 0,
          ),
        );
    await db
        .into(db.refunds)
        .insert(
          RefundsCompanion.insert(
            id: 'local-r1',
            saleId: remoteSaleId,
            shiftId: 'shift-1',
            cashierId: 'cashier-1',
            method: 'cash',
            totalTiyin: 800000,
            at: DateTime.utc(2026, 10, 15, 5),
          ),
        );
    await db
        .into(db.refundItems)
        .insert(
          RefundItemsCompanion.insert(
            id: 'local-ri1',
            refundId: 'local-r1',
            saleItemId: remoteItemId,
            qtyMilli: 2000,
            totalTiyin: 800000,
          ),
        );
    final sale = ((await find('D2-000007')) as RemoteSaleFound).sale;
    expect(sale.refundable.fullyRefunded, isTrue);
    expect(sale.status, 'refunded');
    expect(sale.refunds.map((r) => r.id), [
      '01900000-0000-7000-8000-000000000203',
      'local-r1',
    ]);
    expect(sale.refundable.refundedTiyin, 1200000);
  });

  test('404 → not found, no answer → offline, 500 → failed', () async {
    reply = () => (404, {'detail': 'Not found.'});
    expect(await find('D2-000099'), isA<RemoteSaleNotFound>());
    reply = () => null;
    expect(await find('D2-000099'), isA<RemoteSaleOffline>());
    reply = () => (500, null);
    expect(await find('D2-000099'), isA<RemoteSaleFailed>());
    reply = () => (200, remoteSaleJson());
  });

  test('receipt number pattern', () {
    expect(looksLikeReceiptNumber('D3-000123'), isTrue);
    expect(looksLikeReceiptNumber(' d12-7 '), isTrue);
    expect(looksLikeReceiptNumber('4780000000014'), isFalse);
    expect(looksLikeReceiptNumber('non'), isFalse);
  });
}
