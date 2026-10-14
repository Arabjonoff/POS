import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/sqlite.dart';

CatalogProduct product(
  String id,
  String name, {
  int price = 100000,
  List<String> barcodes = const [],
  String? plu,
  bool active = true,
  bool quick = false,
  String? category,
}) => CatalogProduct(
  id: id,
  name: name,
  priceTiyin: price,
  costTiyin: 0,
  unit: plu == null ? 'dona' : 'kg',
  isWeighted: plu != null,
  isActive: active,
  quickButton: quick,
  categoryId: category,
  pluCode: plu,
  barcodes: barcodes,
);

void main() {
  final catalog = ProductCatalog(
    [
      product(
        'p1',
        'Non',
        barcodes: ['4780000000017'],
        quick: true,
        category: 'c1',
      ),
      product(
        'p2',
        'Coca-Cola 1,5 L',
        barcodes: ['5449000000996', '5449000000439'],
      ),
      product('p3', "O'rik quritilgan", plu: '12345'),
      product('p4', 'Молоко 2,5%', barcodes: ['4600000000018']),
      product('p5', 'Shokoladli non', quick: true, category: 'c2'),
      product('p6', 'Eski tovar', barcodes: ['4780000000024'], active: false),
      product('p7', 'Tuxum', quick: true, category: 'c1'),
    ],
    categories: const [
      QuickCategory(id: 'c1', name: 'Non va tuxum'),
      QuickCategory(id: 'c2', name: 'Shirinlik'),
      QuickCategory(id: 'c3', name: "Bo'sh"),
    ],
  );

  group('byCode', () {
    test('any barcode of the product', () {
      expect(catalog.byCode('5449000000439')!.product.id, 'p2');
      expect(catalog.byCode(' 4780000000017 ')!.product.id, 'p1');
      expect(catalog.byCode('4780000000017')!.weighted, isFalse);
    });

    test('scale barcode → PLU and weight', () {
      final match = catalog.byCode('2012345012509')!;
      expect(match.product.id, 'p3');
      expect(match.qtyMilli, 1250);
      expect(match.weighted, isTrue);
    });

    test('inactive product is found but not sellable', () {
      final match = catalog.byCode('4780000000024')!;
      expect(match.product.sellable, isFalse);
    });

    test('unknown code', () {
      expect(catalog.byCode('4780000000031'), isNull);
      expect(catalog.byCode('2099999012503'), isNull);
    });
  });

  group('search', () {
    List<String> ids(String q) => [for (final p in catalog.search(q)) p.id];

    test('name prefix first, then word prefix, then inside', () {
      expect(ids('non'), ['p1', 'p5']);
      expect(ids('ola'), ['p2', 'p5']);
    });

    test('latin query finds cyrillic name and back', () {
      expect(ids('moloko'), ['p4']);
      expect(ids('орик'), ['p3']);
      expect(ids("o'rik"), ['p3']);
    });

    test('words in any order', () {
      expect(ids('quritilgan orik'), ['p3']);
      expect(ids('cola coca'), ['p2']);
    });

    test('barcode start and exact PLU', () {
      expect(ids('5449'), ['p2']);
      expect(ids('12345'), ['p3']);
      expect(ids('47800'), ['p1']);
    });

    test('inactive products are hidden; empty query → nothing', () {
      expect(ids('eski'), isEmpty);
      expect(ids('  '), isEmpty);
    });
  });

  test('quick buttons by category; empty categories hidden', () {
    expect([for (final p in catalog.quick()) p.id], ['p1', 'p5', 'p7']);
    expect(
      [for (final p in catalog.quick(categoryId: 'c1')) p.id],
      ['p1', 'p7'],
    );
    expect([for (final c in catalog.quickCategories) c.id], ['c1', 'c2']);
  });

  test('search over 10 000 products stays under 50 ms per keystroke', () {
    final words = [
      'Non',
      'Sut',
      'Choy',
      'Shakar',
      'Guruch',
      'Yog',
      'Olma',
      'Pishloq',
    ];
    final big = ProductCatalog([
      for (var i = 0; i < 10000; i++)
        product(
          'x$i',
          '${words[i % words.length]} ${words[(i ~/ 8) % words.length]} $i',
          barcodes: ['${4780000000000 + i}'],
        ),
    ]);
    const typed = [
      's',
      'sh',
      'sha',
      'shak',
      'shaka',
      'shakar',
      'shakar c',
      'shakar ch',
    ];
    // Isitish (JIT).
    big.search('choy');
    final watch = Stopwatch()..start();
    final results = typed.map(big.search).toList();
    watch.stop();
    expect(results.last, isNotEmpty);
    final perKeystroke = watch.elapsedMicroseconds / typed.length / 1000;
    expect(perKeystroke, lessThan(50), reason: '$perKeystroke ms');
  });

  test(
    'loads from the local database with units, barcodes, categories',
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);
      await db.batch((b) {
        b
          ..insert(db.units, UnitsCompanion.insert(id: 'u1', code: 'kg'))
          ..insert(
            db.categories,
            CategoriesCompanion.insert(id: 'c1', name: 'Mevalar'),
          )
          ..insert(
            db.products,
            ProductsCompanion.insert(
              id: 'p1',
              name: 'Olma',
              unitId: 'u1',
              sellPriceTiyin: 1500000,
              categoryId: const Value('c1'),
              quickButton: const Value(true),
            ),
          )
          ..insert(
            db.products,
            ProductsCompanion.insert(
              id: 'p2',
              name: "O'chirilgan",
              unitId: 'u1',
              sellPriceTiyin: 100,
              deletedAt: Value(DateTime.utc(2026)),
            ),
          )
          ..insert(
            db.productBarcodes,
            ProductBarcodesCompanion.insert(barcode: '222', productId: 'p1'),
          )
          ..insert(
            db.productBarcodes,
            ProductBarcodesCompanion.insert(
              barcode: '111',
              productId: 'p1',
              isPrimary: const Value(true),
            ),
          );
      });
      final loaded = await ProductCatalog.load(db);
      expect(loaded.length, 1);
      final olma = loaded.byId('p1')!;
      expect(olma.unit, 'kg');
      expect(olma.barcodes, ['111', '222']);
      expect(olma.primaryBarcode, '111');
      expect(loaded.byId('p2'), isNull);
      expect([for (final c in loaded.quickCategories) c.name], ['Mevalar']);
    },
  );
}
