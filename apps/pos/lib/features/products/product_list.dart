import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/core/text/search_key.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Tovarlar ro'yxati qatori (o'chirilmaganlar, nofaollar ham).
class ProductRow {
  const ProductRow({
    required this.id,
    required this.name,
    required this.searchKey,
    required this.unit,
    required this.priceTiyin,
    required this.costTiyin,
    required this.isActive,
    this.barcodes = const [],
    this.categoryId,
    this.categoryName,
    this.pluCode,
    this.minStockMilli = 0,
    this.stockMilli = 0,
  });

  final String id;
  final String name;
  final String searchKey;
  final UnitCode unit;
  final int priceTiyin;
  final int costTiyin;
  final bool isActive;

  /// Birinchisi — asosiy.
  final List<String> barcodes;
  final String? categoryId;
  final String? categoryName;
  final String? pluCode;
  final int minStockMilli;
  final int stockMilli;

  bool get negative => stockMilli < 0;

  /// "Kam qolgan": minimal qoldiq berilgan va qoldiq undan oshmaydi.
  bool get low => isActive && minStockMilli > 0 && stockMilli <= minStockMilli;

  ProductRow withStock(int stock) => ProductRow(
    id: id,
    name: name,
    searchKey: searchKey,
    unit: unit,
    priceTiyin: priceTiyin,
    costTiyin: costTiyin,
    isActive: isActive,
    barcodes: barcodes,
    categoryId: categoryId,
    categoryName: categoryName,
    pluCode: pluCode,
    minStockMilli: minStockMilli,
    stockMilli: stock,
  );
}

/// Ro'yxat filtri (`products.md`): faol, kam qolgan, manfiy, nofaol.
enum ProductFilter { active, low, negative, inactive }

/// Qidiruv va filtrlash — sof funksiya: nom (lotin/kirill farqsiz, so'zlar
/// istalgan tartibda), shtrix-kod boshi (≥ 3 belgi) yoki aniq PLU.
List<ProductRow> filterProducts(
  List<ProductRow> rows, {
  String query = '',
  String? categoryId,
  ProductFilter filter = ProductFilter.active,
}) {
  final key = SearchKey.of(query);
  final tokens = key.isEmpty ? const <String>[] : key.split(' ');
  final code = query.trim();
  bool matches(ProductRow r) {
    if (key.isEmpty) return true;
    if (tokens.every(r.searchKey.contains)) return true;
    if (code.length >= 3 && r.barcodes.any((b) => b.startsWith(code))) {
      return true;
    }
    return r.pluCode != null && r.pluCode == code;
  }

  return [
    for (final r in rows)
      if ((categoryId == null || r.categoryId == categoryId) &&
          switch (filter) {
            ProductFilter.active => r.isActive,
            ProductFilter.low => r.low,
            ProductFilter.negative => r.negative,
            ProductFilter.inactive => !r.isActive,
          } &&
          matches(r))
        r,
  ];
}

class ProductCategory {
  const ProductCategory({required this.id, required this.name});

  final String id;
  final String name;
}

/// Kategoriyalar (tartib bo'yicha).
final productCategoriesProvider = StreamProvider<List<ProductCategory>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.categories)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([
          (c) => OrderingTerm.asc(c.sort),
          (c) => OrderingTerm.asc(c.name),
        ]))
      .watch()
      .map(
        (rows) => [
          for (final c in rows) ProductCategory(id: c.id, name: c.name),
        ],
      );
});

final _productBaseProvider = StreamProvider<List<ProductRow>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .customSelect(
        'SELECT p.id, p.name, p.search_key, p.category_id, c.name AS category, '
        'u.code AS unit, p.sell_price_tiyin, p.cost_price_tiyin, p.is_active, '
        'p.plu_code, p.min_stock_milli, '
        "(SELECT group_concat(barcode, ' ') FROM ( "
        'SELECT b.barcode FROM product_barcodes b WHERE b.product_id = p.id '
        'ORDER BY b.is_primary DESC, b.barcode)) AS barcodes '
        'FROM products p '
        'LEFT JOIN categories c ON c.id = p.category_id AND c.deleted_at IS NULL '
        'LEFT JOIN units u ON u.id = p.unit_id '
        'WHERE p.deleted_at IS NULL ORDER BY p.name',
        readsFrom: {db.products, db.productBarcodes, db.categories, db.units},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            ProductRow(
              id: r.read<String>('id'),
              name: r.read<String>('name'),
              searchKey: r.read<String>('search_key').isEmpty
                  ? SearchKey.of(r.read<String>('name'))
                  : r.read<String>('search_key'),
              categoryId: r.readNullable<String>('category_id'),
              categoryName: r.readNullable<String>('category'),
              unit: UnitCode.fromCode(r.readNullable<String>('unit')),
              priceTiyin: r.read<int>('sell_price_tiyin'),
              costTiyin: r.read<int>('cost_price_tiyin'),
              isActive: r.read<bool>('is_active'),
              pluCode: r.readNullable<String>('plu_code'),
              minStockMilli: r.read<int>('min_stock_milli'),
              barcodes: (r.readNullable<String>('barcodes') ?? '')
                  .split(' ')
                  .where((b) => b.isNotEmpty)
                  .toList(),
            ),
        ],
      );
});

/// Ro'yxat qoldiq bilan (`null` — yuklanmoqda).
final productRowsProvider = Provider<List<ProductRow>?>((ref) {
  final base = ref.watch(_productBaseProvider).value;
  if (base == null) return null;
  final stock = ref.watch(stockByProductProvider).value ?? const {};
  return [for (final r in base) r.withStock(stock[r.id] ?? 0)];
});
