import 'package:drift/drift.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Namuna katalog: kategoriyalar, birliklar, tez tugmali va shtrix-kodli
/// tovarlar (kassa ekrani testlari va golden'lar uchun).
Future<void> seedCatalog(AppDatabase db) async {
  await db.batch((b) {
    b
      ..insertAll(db.units, [
        UnitsCompanion.insert(id: 'u-pcs', code: 'pcs'),
        UnitsCompanion.insert(
          id: 'u-kg',
          code: 'kg',
          isFractional: const Value(true),
        ),
      ])
      ..insertAll(db.categories, [
        CategoriesCompanion.insert(
          id: 'c-bread',
          name: 'Non',
          sort: const Value(1),
        ),
        CategoriesCompanion.insert(
          id: 'c-veg',
          name: 'Sabzavot',
          sort: const Value(2),
        ),
        CategoriesCompanion.insert(
          id: 'c-milk',
          name: 'Sut',
          sort: const Value(3),
        ),
      ]);
    for (final (id, name, price, unit, category, quick, plu) in const [
      ('p-non', 'Non issiq', 400000, 'u-pcs', 'c-bread', true, null),
      ('p-patir', 'Patir non', 800000, 'u-pcs', 'c-bread', true, null),
      ('p-tuxum', 'Tuxum', 150000, 'u-pcs', 'c-milk', true, null),
      ('p-sut', 'Sut 1 L', 1200000, 'u-pcs', 'c-milk', true, null),
      ('p-kartoshka', 'Kartoshka', 600000, 'u-kg', 'c-veg', true, '10001'),
      ('p-piyoz', 'Piyoz', 450000, 'u-kg', 'c-veg', true, '10002'),
      ('p-olma', 'Olma qizil', 1500000, 'u-kg', 'c-veg', true, '12345'),
      ('p-cola', 'Coca-Cola 1,5 L', 1400000, 'u-pcs', null, false, null),
      ('p-choy', 'Choy Ahmad 100 g', 2300000, 'u-pcs', null, false, null),
      ('p-shakar', 'Shakar 1 kg', 1350000, 'u-pcs', null, false, null),
      ('p-nonvoy', 'Nonvoy pechenyesi', 900000, 'u-pcs', null, false, null),
    ]) {
      b.insert(
        db.products,
        ProductsCompanion.insert(
          id: id,
          name: name,
          unitId: unit,
          sellPriceTiyin: price,
          categoryId: Value(category),
          quickButton: Value(quick),
          isWeighted: Value(plu != null),
          pluCode: Value(plu),
        ),
      );
    }
    b
      ..insert(
        db.products,
        ProductsCompanion.insert(
          id: 'p-old',
          name: 'Eski tovar',
          unitId: 'u-pcs',
          sellPriceTiyin: 100000,
          isActive: const Value(false),
        ),
      )
      ..insertAll(db.productBarcodes, [
        ProductBarcodesCompanion.insert(
          barcode: '4780000000014',
          productId: 'p-non',
        ),
        ProductBarcodesCompanion.insert(
          barcode: '5449000000996',
          productId: 'p-cola',
        ),
        ProductBarcodesCompanion.insert(
          barcode: '4780000000021',
          productId: 'p-old',
        ),
        ProductBarcodesCompanion.insert(
          barcode: '4600000000015',
          productId: 'p-sut',
        ),
      ]);
  });
}
