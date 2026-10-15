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
      'at': '2026-10-15T09:00:00.000Z',
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

  group('correction and cancel (T-102)', () {
    Future<Map<String, int>> stock() async =>
        Map.fromEntries(await stockQuery(db).get());

    Future<String> postedReceipt(int qtyMilli, {int cost = 300000}) async {
      final id = await store.create();
      await store.addProduct(id, 'p-non', qtyMilli: qtyMilli);
      final line = (await doc(id)).lines.single.id;
      await store.setCost(line, cost);
      await store.post(id, by: 'manager-1', storeId: 'store-1');
      return id;
    }

    test(
      '10 → 7: stock changes by −3 exactly once, one outbox event',
      () async {
        final original = await postedReceipt(10000);
        expect((await stock())['p-non'], 10000);

        final draft = await store.startCorrection(original);
        // Qoralama — asl kirim nusxasi; qayta boshlash o'sha qoralamani beradi.
        expect(await store.startCorrection(original), draft);
        var d = await doc(draft);
        expect(d.isCorrection, isTrue);
        expect(d.lines.single.qtyMilli, 10000);
        // Qoralama qoldiqqa ta'sir qilmaydi.
        expect((await stock())['p-non'], 10000);

        await store.setQty(d.lines.single.id, 7000);
        await store.postCorrection(draft, by: 'manager-1', storeId: 'store-1');
        expect((await stock())['p-non'], 7000);

        // Asl kirim o'zgarmagan, "tuzatilgan"; yangi versiya — amaldagi.
        final old = await doc(original);
        expect(old.lines.single.qtyMilli, 10000);
        expect(old.isCorrected, isTrue);
        expect(old.isActiveVersion, isFalse);
        d = await doc(draft);
        expect((d.status, d.isActiveVersion), ('posted', true));
        expect(d.postedAt, old.postedAt); // hujjat sanasi — asl kirimniki

        final events = await (db.select(
          db.outboxEvents,
        )..where((e) => e.type.equals(OutboxEventType.receiptCorrected))).get();
        final payload =
            jsonDecode(events.single.payload) as Map<String, Object?>;
        expect(payload['id'], draft);
        expect(payload['corrects'], original);
        expect(payload['items'], [
          {'product': 'p-non', 'qty_milli': 7000, 'cost_price_tiyin': 300000},
        ]);
        // Harakatlar hammasi shu bitta hodisaga bog'langan (yuborilgach birga
        // server qoldig'iga almashadi — ikki marta hisoblanmaydi).
        final movements = await (db.select(
          db.stockMovements,
        )..where((m) => m.outboxEventId.equals(events.single.id))).get();
        expect([for (final m in movements) m.qtyMilli]..sort(), [-10000, 7000]);

        // Tuzatilgan kirimni qayta tuzatib/bekor qilib bo'lmaydi.
        await expectLater(
          store.startCorrection(original),
          throwsA(isA<ReceiptNotEditableException>()),
        );
        await expectLater(
          store.cancel(original, by: 'manager-1'),
          throwsA(isA<ReceiptNotEditableException>()),
        );
        // Ro'yxatda teskari yozuv ko'rinmaydi; asl kirim — "tuzatilgan".
        final list = await store.watchAll().first;
        expect(
          {for (final r in list) r.id: (r.state, r.isCorrection)},
          {
            original: (ReceiptState.corrected, false),
            draft: (ReceiptState.posted, true),
          },
        );
      },
    );

    test('correction can be corrected again (chain)', () async {
      final original = await postedReceipt(10000);
      final v2 = await store.startCorrection(original);
      await store.setQty((await doc(v2)).lines.single.id, 7000);
      await store.postCorrection(v2, by: 'm', storeId: 'store-1');
      final v3 = await store.startCorrection(v2);
      await store.setQty((await doc(v3)).lines.single.id, 12000);
      await store.postCorrection(v3, by: 'm', storeId: 'store-1');
      expect((await stock())['p-non'], 12000);
    });

    test('dropping the draft discards the correction', () async {
      final original = await postedReceipt(10000);
      final draft = await store.startCorrection(original);
      await store.deleteDraft(draft);
      expect((await doc(original)).isActiveVersion, isTrue);
      expect((await stock())['p-non'], 10000);
    });

    test('empty correction cannot be saved (use cancel)', () async {
      final original = await postedReceipt(10000);
      final draft = await store.startCorrection(original);
      await store.removeLine((await doc(draft)).lines.single.id);
      await expectLater(
        store.postCorrection(draft, by: 'm'),
        throwsA(isA<ReceiptEmptyException>()),
      );
      expect((await stock())['p-non'], 10000);
    });

    test('cancel: stock back, receipt.reversed, prices kept', () async {
      final original = await postedReceipt(10000, cost: 320000);
      final draft = await store.startCorrection(original);
      await store.cancel(original, by: 'manager-1', note: 'Xato kirim');
      expect((await stock())['p-non'], 0);
      // Ochiq tuzatish qoralamasi ham o'chdi.
      expect(await store.load(draft), isNull);
      final d = await doc(original);
      expect((d.cancelled, d.isActiveVersion), (true, false));
      final event =
          await (db.select(db.outboxEvents)
                ..where((e) => e.type.equals(OutboxEventType.receiptReversed)))
              .getSingle();
      final payload = jsonDecode(event.payload) as Map<String, Object?>;
      expect(
        (payload['reverses'], payload['note'], payload['by']),
        (original, 'Xato kirim', 'manager-1'),
      );
      final non = await (db.select(
        db.products,
      )..where((p) => p.id.equals('p-non'))).getSingle();
      expect(non.costPriceTiyin, 320000);
      // Ikkinchi marta bekor qilib bo'lmaydi.
      await expectLater(
        store.cancel(original, by: 'm'),
        throwsA(isA<ReceiptNotEditableException>()),
      );
      expect(
        (await store.watchAll().first).single.state,
        ReceiptState.cancelled,
      );
    });

    test('old receipt correction keeps the newer cost', () async {
      final old = await postedReceipt(10000);
      await store.post(
        await () async {
          final id = await store.create();
          await store.addProduct(id, 'p-non', qtyMilli: 5000);
          await store.setCost((await doc(id)).lines.single.id, 350000);
          return id;
        }(),
        by: 'm',
      );
      // Ikkala kirim bir vaqtda (soxta soat) — keyingisini "keyinroq" qilamiz.
      await (db.update(db.stockReceipts)..where((r) => r.id.equals(old))).write(
        StockReceiptsCompanion(
          postedAt: Value(DateTime.utc(2026, 10, 14)),
        ),
      );
      final draft = await store.startCorrection(old);
      await store.setCost((await doc(draft)).lines.single.id, 310000);
      await store.postCorrection(draft, by: 'm');
      final non = await (db.select(
        db.products,
      )..where((p) => p.id.equals('p-non'))).getSingle();
      expect(non.costPriceTiyin, 350000);
    });

    test('a draft or a reversal cannot be corrected', () async {
      final draft = await store.create();
      await expectLater(
        store.startCorrection(draft),
        throwsA(isA<ReceiptNotEditableException>()),
      );
    });
  });
}
