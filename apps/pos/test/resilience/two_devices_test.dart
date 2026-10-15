import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_editor.dart' show stockQuery;
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/data/sync/sync_engine.dart';

import '../helpers/fake_sync_server.dart';
import '../helpers/sqlite.dart';

/// Bir do'konda 2 kassa bir tovarni oflayn sotadi, keyin sinxronlanadi:
/// ikkalasi ham server qoldig'iga yaqinlashadi (`sync.md`, T-090).
class Kassa {
  Kassa(this.server, this.number) : db = openTestDatabase() {
    engine = SyncEngine(
      db,
      () async => deviceApi(server.http.dio, 'device-$number'),
      now: () => now,
    );
  }

  final FakeSyncServer server;
  final int number;
  final AppDatabase db;
  late final SyncEngine engine;
  DateTime now = DateTime.utc(2026, 10, 14, 10);

  Future<void> setUp() => db.batch((b) {
    b
      ..insert(
        db.shifts,
        ShiftsCompanion.insert(
          id: 'shift-$number',
          storeId: 'store-1',
          deviceId: 'device-$number',
          openedBy: 'u',
          openedAt: now,
          openingCashTiyin: 0,
        ),
      )
      ..insert(
        db.products,
        ProductsCompanion.insert(
          id: 'bread',
          name: 'Non',
          unitId: 'pcs',
          sellPriceTiyin: 500000,
          costPriceTiyin: const Value(400000),
        ),
      );
  });

  Future<void> sell(int pieces) async {
    now = now.add(const Duration(minutes: 1));
    await SaleWriter(db, deviceNumber: number, now: () => now).complete(
      CompletedSaleInput(
        shiftId: 'shift-$number',
        cashierId: 'u',
        lines: [
          SaleLineInput(
            productId: 'bread',
            name: 'Non',
            qtyMilli: pieces * 1000,
            priceTiyin: 500000,
            costTiyin: 400000,
          ),
        ],
        payments: [SalePaymentInput.card(amountTiyin: 500000 * pieces)],
      ),
    );
  }

  /// Oflayn urinishdan keyingi kutish (backoff) o'tsin.
  void later() => now = now.add(const Duration(minutes: 10));

  Future<int> stock() async =>
      Map.fromEntries(await stockQuery(db).get())['bread']!;
}

void main() {
  late FakeSyncServer server;
  late Kassa a;
  late Kassa b;

  setUp(() async {
    server = FakeSyncServer()..stock['bread'] = 10000;
    a = Kassa(server, 1);
    b = Kassa(server, 2);
    await a.setUp();
    await b.setUp();
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('two kassas sell the same product offline → both converge', () async {
    // Boshida ikkalasi serverdan 10 dona oladi.
    await a.engine.syncOnce();
    await b.engine.syncOnce();
    expect((await a.stock(), await b.stock()), (10000, 10000));

    // Internet yo'q: A — 1, B — 2 dona sotadi; har biri o'z sotuvini ko'radi.
    server.offline = true;
    await a.sell(1);
    await b.sell(2);
    await a.engine.syncOnce();
    await b.engine.syncOnce();
    expect((await a.stock(), await b.stock()), (9000, 8000));

    // Internet qaytdi: A birinchi — server 9, B hali o'zinikini yubormagan.
    server.offline = false;
    a.later();
    b.later();
    await a.engine.syncOnce();
    expect(server.stock['bread'], 9000);
    expect(await a.stock(), 9000);

    // B yuboradi: server 7; keyin A ham yangilanadi — ikki marta ayirilmaydi.
    await b.engine.syncOnce();
    await a.engine.syncOnce();
    expect(server.stock['bread'], 7000);
    expect((await a.stock(), await b.stock()), (7000, 7000));
    expect(server.applied.length, 2);
  });

  test('a lost push response does not sell twice', () async {
    await a.engine.syncOnce();
    await a.sell(1);
    server.loseNextResponse = true;
    await a.engine.syncOnce();
    a.later();
    // Server qo'lladi, javob yo'qoldi — kassa qayta yuboradi (duplicate).
    await a.engine.syncOnce();
    expect(server.applied.length, 1);
    expect(server.stock['bread'], 9000);
    expect(await a.stock(), 9000);
  });
}
