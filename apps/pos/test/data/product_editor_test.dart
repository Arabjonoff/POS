import 'dart:convert';

import 'package:drift/drift.dart' show Value, Variable;

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/text/search_key.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/outbox.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;
  late ProductEditor editor;

  setUp(() async {
    db = openTestDatabase();
    await seedCatalog(db);
    editor = ProductEditor(db, now: () => DateTime.utc(2026, 10, 15, 9));
  });
  tearDown(() => db.close());

  Future<List<ProductProblemCode>> codes(ProductDraft d) async => [
    for (final p in await editor.validate(d)) p.code,
  ];

  const base = ProductDraft(
    name: 'Qatiq 0,5 L',
    unitId: 'u-pcs',
    sellPriceTiyin: 900000,
    costPriceTiyin: 700000,
  );

  test('new product: local row, barcodes, outbox product.upserted', () async {
    final id = await editor.save(
      base.copyWith(
        barcodes: [' 4780000000045 ', 'QTQ-05'],
        categoryId: 'c-milk',
      ),
      by: 'manager-1',
    );
    final p = await (db.select(
      db.products,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(
      (p.name, p.searchKey, p.categoryId),
      (
        'Qatiq 0,5 L',
        SearchKey.of('Qatiq 0,5 L'),
        'c-milk',
      ),
    );
    final barcodes = await (db.select(
      db.productBarcodes,
    )..where((b) => b.productId.equals(id))).get();
    expect(
      {for (final b in barcodes) b.barcode: b.isPrimary},
      {
        '4780000000045': true,
        'QTQ-05': false,
      },
    );

    final event =
        await (db.select(
              db.outboxEvents,
            )..where((e) => e.type.equals(OutboxEventType.productUpserted)))
            .getSingle();
    final payload = jsonDecode(event.payload) as Map<String, Object?>;
    expect(payload, {
      'id': id,
      'name': 'Qatiq 0,5 L',
      'category': 'c-milk',
      'unit': 'u-pcs',
      'sell_price_tiyin': 900000,
      'cost_price_tiyin': 700000,
      'is_weighted': false,
      'plu_code': null,
      'min_stock_milli': 0,
      'ikpu_code': '',
      'quick_button': false,
      'is_active': true,
      'barcodes': ['4780000000045', 'QTQ-05'],
      'by': 'manager-1',
    });
  });

  test('edit keeps the id; barcode list is replaced', () async {
    final draft = (await editor.load('p-non'))!;
    expect(draft.barcodes, ['4780000000014']);
    await editor.save(
      draft.copyWith(sellPriceTiyin: 450000, barcodes: ['NON-1']),
      by: 'owner-1',
    );
    final again = (await editor.load('p-non'))!;
    expect(again.sellPriceTiyin, 450000);
    expect(again.barcodes, ['NON-1']);
    expect(await editor.ownerOf('4780000000014'), isNull);
    expect((await editor.ownerOf('NON-1'))!.productId, 'p-non');
  });

  test('edit sends only the changed fields (audit PR-P1-4)', () async {
    final draft = (await editor.load('p-non'))!;
    await editor.save(draft.copyWith(name: 'Non yangi'), by: 'owner-1');
    final event = await db.select(db.outboxEvents).getSingle();
    // Narx, shtrix-kodlar va boshqalar yuborilmaydi — serverdagi yangiroq
    // qiymatlarni eski oflayn tahrir bosib ketmaydi.
    expect(jsonDecode(event.payload), {
      'id': 'p-non',
      'name': 'Non yangi',
      'by': 'owner-1',
    });
  });

  test('validation: required, price, barcode rules, PLU, IKPU', () async {
    expect(await codes(const ProductDraft()), [
      ProductProblemCode.required,
      ProductProblemCode.required,
      ProductProblemCode.notPositive,
    ]);
    final problems = await editor.validate(
      base.copyWith(
        barcodes: [
          '4780000000015', // nazorat raqami xato
          'a b',
          '5449000000996', // Coca-Cola'da
          'XY-12',
          'XY-12',
        ],
        pluCode: '1234',
        ikpuCode: '123',
      ),
    );
    expect(
      [for (final p in problems) p.code],
      [
        ProductProblemCode.barcodeCheckDigit,
        ProductProblemCode.barcodeFormat,
        ProductProblemCode.barcodeTaken,
        ProductProblemCode.barcodeRepeated,
        ProductProblemCode.pluFormat,
        ProductProblemCode.ikpuFormat,
      ],
    );
    expect(problems[2].otherProduct, 'Coca-Cola 1,5 L');
  });

  test('weighted needs a fractional unit; PLU must be free', () async {
    expect(await codes(base.copyWith(isWeighted: true)), [
      ProductProblemCode.weightedNeedsFractionalUnit,
    ]);
    final taken = await editor.validate(
      base.copyWith(unitId: 'u-kg', isWeighted: true, pluCode: '12345'),
    );
    expect(taken.single.code, ProductProblemCode.pluTaken);
    expect(taken.single.otherProduct, 'Olma qizil');
    // O'zining PLU si — xato emas.
    final olma = (await editor.load('p-olma'))!;
    expect(await editor.validate(olma), isEmpty);
  });

  test(
    'name ≤ 200 chars, ≤ 20 barcodes (server limits, audit PR-P1-3)',
    () async {
      expect(await codes(base.copyWith(name: 'a' * 200)), isEmpty);
      expect(await codes(base.copyWith(name: 'a' * 201)), [
        ProductProblemCode.tooLong,
      ]);
      // Emoji — bitta belgi (server kod nuqtalarini sanaydi).
      expect(await codes(base.copyWith(name: '🍎' * 200)), isEmpty);
      final many = [for (var i = 0; i < 21; i++) 'CODE-$i'];
      expect(await codes(base.copyWith(barcodes: many)), [
        ProductProblemCode.tooManyBarcodes,
      ]);
    },
  );

  test('name: control characters and extra spaces are removed', () async {
    final id = await editor.save(
      base.copyWith(name: "  Yog'\n 1\u0000 l\t "),
      by: 'manager-1',
    );
    final p = await (db.select(
      db.products,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(p.name, "Yog' 1 l");
    final event = await db.select(db.outboxEvents).getSingle();
    expect((jsonDecode(event.payload) as Map)['name'], "Yog' 1 l");
    expect(await codes(base.copyWith(name: '\n\t')), [
      ProductProblemCode.required,
    ]);
  });

  test('invalid draft is not saved', () async {
    await expectLater(
      editor.save(const ProductDraft(name: 'X'), by: 'm'),
      throwsA(isA<InvalidProductException>()),
    );
    expect(await db.select(db.outboxEvents).get(), isEmpty);
  });

  test('markup in basis points (server formula)', () {
    expect(base.markupBp, 2857); // (9 000 − 7 000) / 7 000 = 28,57%
    expect(base.copyWith(costPriceTiyin: 0).markupBp, isNull);
    expect(base.copyWith(sellPriceTiyin: 600000).markupBp, -1429);
  });

  test('stock = server value + unsent local movements', () async {
    expect((await _stock(db))['p-non'], 0);
    await db
        .into(db.productStock)
        .insert(
          ProductStockCompanion.insert(
            productId: 'p-non',
            storeId: 'store-1',
            qtyMilli: 10000,
            updatedAt: DateTime.utc(2026, 10, 15),
          ),
        );
    Future<void> move(String id, int qty, String status) async {
      await db.enqueueEvent(
        id: 'e-$id',
        type: OutboxEventType.saleCompleted,
        createdAt: DateTime.utc(2026, 10, 15),
        payload: const {},
      );
      await (db.update(db.outboxEvents)..where((e) => e.id.equals('e-$id')))
          .write(OutboxEventsCompanion.custom(status: Variable(status)));
      await db
          .into(db.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: id,
              productId: 'p-non',
              qtyMilli: qty,
              type: 'sale',
              refType: 'sale',
              refId: 's',
              outboxEventId: Value('e-$id'),
              at: DateTime.utc(2026, 10, 15),
            ),
          );
    }

    await move('m1', -3000, 'pending'); // hali yuborilmagan — hisobga olinadi
    await move('m2', -2000, 'sent'); // serverdagi qiymatda bor
    expect((await _stock(db))['p-non'], 7000);
  });
}

Future<Map<String, int>> _stock(AppDatabase db) async =>
    Map.fromEntries(await stockQuery(db).get());
