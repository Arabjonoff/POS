import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/receipts/receipt_store.dart';
import 'package:pos_app/data/sync/outbox.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late ReceiptStore store;

  setUp(() async {
    db = openTestDatabase();
    await seedCatalog(db);
    await (db.update(db.products)..where((p) => p.id.equals('p-non'))).write(
      const ProductsCompanion(costPriceTiyin: Value(300000)),
    );
    store = ReceiptStore(db, now: () => DateTime.utc(2026, 10, 15, 9));
  });
  tearDown(() => db.close());

  Future<ReceiptDoc> doc(String id) async => (await store.load(id))!;

  test('100 scans of 3 products → 3 lines with the right counts', () async {
    final id = await store.create();
    for (var i = 0; i < 100; i++) {
      await store.addProduct(id, switch (i % 4) {
        0 || 1 => 'p-non',
        2 => 'p-cola',
        _ => 'p-sut',
      });
    }
    final d = await doc(id);
    expect(
      [for (final l in d.lines) (l.productId, l.qtyMilli)],
      [
        ('p-non', 50000),
        ('p-cola', 25000),
        ('p-sut', 25000),
      ],
    );
    // Oxirgi tannarx oldindan; jami = 50 × 3 000.
    expect(d.lines.first.costTiyin, 300000);
    expect(d.totalCostTiyin, 15000000);
  });

  test('edit qty/cost/price; same price = no change; remove line', () async {
    final id = await store.create();
    await store.addProduct(id, 'p-non');
    await store.addProduct(id, 'p-olma', qtyMilli: 1250);
    var d = await doc(id);
    final non = d.lines.first.id;
    await store.setQty(non, 12000);
    await store.setCost(non, 320000);
    await store.setSellPrice(non, 380000);
    d = await doc(id);
    expect(d.lines.first.qtyMilli, 12000);
    expect(d.lines.first.newSellTiyin, 380000);
    expect(d.lines.first.sellBelowCost, isFalse);
    await store.setSellPrice(non, 300000);
    expect((await doc(id)).lines.first.sellBelowCost, isTrue);
    await store.setSellPrice(non, 400000); // hozirgi narx
    expect((await doc(id)).lines.first.newSellTiyin, isNull);
    expect(() => store.setQty(non, 0), throwsArgumentError);

    await store.removeLine(d.lines.last.id);
    d = await doc(id);
    expect(d.lines, hasLength(1));
    expect(d.totalCostTiyin, 12 * 320000);
  });

  test('post: stock up, prices updated, receipt.posted payload', () async {
    final id = await store.create();
    final supplier = await store.createSupplier(
      name: 'Ulgurji Non',
      phone: '+998 90 000 00 00',
      by: 'manager-1',
    );
    await store.setSupplier(id, supplier);
    await store.setNote(id, 'Ertalabki');
    await store.addProduct(id, 'p-non', qtyMilli: 20000);
    await store.addProduct(id, 'p-cola', qtyMilli: 6000);
    final d = await doc(id);
    await store.setCost(d.lines.first.id, 320000);
    await store.setSellPrice(d.lines.first.id, 450000);

    await store.post(id, by: 'manager-1', storeId: 'store-1');

    final posted = await doc(id);
    expect(posted.status, 'posted');
    expect(posted.supplierName, 'Ulgurji Non');
    final stock = Map.fromEntries(await stockQuery(db).get());
    expect((stock['p-non'], stock['p-cola']), (20000, 6000));
    final non = await (db.select(
      db.products,
    )..where((p) => p.id.equals('p-non'))).getSingle();
    expect((non.costPriceTiyin, non.sellPriceTiyin), (320000, 450000));

    final events = await (db.select(
      db.outboxEvents,
    )..where((e) => e.type.equals(OutboxEventType.receiptPosted))).get();
    final payload = jsonDecode(events.single.payload) as Map<String, Object?>;
    expect(payload, {
      'id': id,
      'supplier': supplier,
      'note': 'Ertalabki',
      'items': [
        {
          'product': 'p-non',
          'qty_milli': 20000,
          'cost_price_tiyin': 320000,
          'new_sell_price_tiyin': 450000,
        },
        {'product': 'p-cola', 'qty_milli': 6000, 'cost_price_tiyin': 0},
      ],
      'by': 'manager-1',
    });
    final supplierEvent =
        await (db.select(
              db.outboxEvents,
            )..where((e) => e.type.equals(OutboxEventType.supplierUpserted)))
            .getSingle();
    expect((jsonDecode(supplierEvent.payload) as Map)['by'], 'manager-1');

    // Tasdiqlangan — qayta tasdiqlash ham, o'chirish ham hech narsa qilmaydi.
    await store.post(id, by: 'manager-1');
    await store.deleteDraft(id);
    expect((await doc(id)).status, 'posted');
    expect(
      Map.fromEntries(await stockQuery(db).get())['p-non'],
      20000,
    );
  });

  test('empty receipt cannot be posted; draft can be deleted', () async {
    final id = await store.create();
    await expectLater(
      store.post(id, by: 'm'),
      throwsA(isA<ReceiptEmptyException>()),
    );
    await store.addProduct(id, 'p-non');
    await store.deleteDraft(id);
    expect(await store.load(id), isNull);
    expect(await db.select(db.stockReceiptItems).get(), isEmpty);
  });

  test('list: drafts first, then posted (newest first)', () async {
    final a = await store.create();
    await store.addProduct(a, 'p-non');
    await store.post(a, by: 'm');
    final b = await store.create();
    final list = await store.watchAll().first;
    expect(
      [for (final r in list) (r.id, r.status, r.lineCount)],
      [
        (b, 'draft', 0),
        (a, 'posted', 1),
      ],
    );
  });
}
