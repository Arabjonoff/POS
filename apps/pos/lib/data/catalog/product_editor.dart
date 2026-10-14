import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/barcode/barcode.dart';
import 'package:pos_app/core/text/search_key.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/sync/outbox.dart';

/// Tovar kartasidagi qiymatlar (`catalog-api.md` maydonlari).
class ProductDraft {
  const ProductDraft({
    this.id,
    this.name = '',
    this.categoryId,
    this.unitId,
    this.sellPriceTiyin = 0,
    this.costPriceTiyin = 0,
    this.isWeighted = false,
    this.pluCode = '',
    this.minStockMilli = 0,
    this.ikpuCode = '',
    this.quickButton = false,
    this.isActive = true,
    this.barcodes = const [],
  });

  /// `null` — yangi tovar.
  final String? id;
  final String name;
  final String? categoryId;
  final String? unitId;
  final int sellPriceTiyin;
  final int costPriceTiyin;
  final bool isWeighted;
  final String pluCode;
  final int minStockMilli;
  final String ikpuCode;
  final bool quickButton;
  final bool isActive;

  /// Birinchisi — asosiy.
  final List<String> barcodes;

  bool get isNew => id == null;

  /// Ustama, bazis punktda: `(narx − tannarx) × 10000 / tannarx`; tannarx
  /// 0 — `null` (server `markup_bp` bilan bir xil).
  int? get markupBp {
    if (costPriceTiyin <= 0) return null;
    final diff = (sellPriceTiyin - costPriceTiyin) * 10000;
    // Half-up, manfiy ham (server `mul_div_half_up`).
    final q = diff.abs() ~/ costPriceTiyin;
    final r = diff.abs() % costPriceTiyin;
    final rounded = r * 2 >= costPriceTiyin ? q + 1 : q;
    return diff < 0 ? -rounded : rounded;
  }

  ProductDraft copyWith({
    String? name,
    String? categoryId,
    bool clearCategory = false,
    String? unitId,
    int? sellPriceTiyin,
    int? costPriceTiyin,
    bool? isWeighted,
    String? pluCode,
    int? minStockMilli,
    String? ikpuCode,
    bool? quickButton,
    bool? isActive,
    List<String>? barcodes,
  }) => ProductDraft(
    id: id,
    name: name ?? this.name,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    unitId: unitId ?? this.unitId,
    sellPriceTiyin: sellPriceTiyin ?? this.sellPriceTiyin,
    costPriceTiyin: costPriceTiyin ?? this.costPriceTiyin,
    isWeighted: isWeighted ?? this.isWeighted,
    pluCode: pluCode ?? this.pluCode,
    minStockMilli: minStockMilli ?? this.minStockMilli,
    ikpuCode: ikpuCode ?? this.ikpuCode,
    quickButton: quickButton ?? this.quickButton,
    isActive: isActive ?? this.isActive,
    barcodes: barcodes ?? this.barcodes,
  );
}

enum ProductField { name, unit, price, barcodes, plu, ikpu }

enum ProductProblemCode {
  required,
  notPositive,
  barcodeFormat,
  barcodeCheckDigit,
  barcodeRepeated,
  barcodeTaken,
  pluFormat,
  pluTaken,
  weightedNeedsFractionalUnit,
  ikpuFormat,
}

/// Tekshiruv xatosi; [barcode] va [otherProduct] — shtrix-kod/PLU band
/// bo'lganda (qaysi tovarda).
class ProductProblem {
  const ProductProblem(
    this.field,
    this.code, {
    this.barcode,
    this.otherProduct,
  });

  final ProductField field;
  final ProductProblemCode code;
  final String? barcode;
  final String? otherProduct;
}

class InvalidProductException implements Exception {
  const InvalidProductException(this.problems);

  final List<ProductProblem> problems;
}

/// Shtrix-kod qaysi tovarda (kassa skaneri uchun).
class BarcodeOwner {
  const BarcodeOwner({required this.productId, required this.productName});

  final String productId;
  final String productName;
}

/// Tovar kartasini tekshirish va saqlash — oflayn: lokal bazaga darhol
/// (kassa katalogi shu zahoti yangilanadi) va outbox `product.upserted`
/// (server faqat ega/menejer `by` bilan qabul qiladi).
class ProductEditor {
  ProductEditor(this._db, {IdGenerator? newId, DateTime Function()? now})
    : _newId = newId ?? _defaultId,
      _now = now ?? _clockNow;

  static String _defaultId() => newId();
  static DateTime _clockNow() => clock.now();

  final AppDatabase _db;
  final IdGenerator _newId;
  final DateTime Function() _now;

  static final RegExp _plu = RegExp(r'^\d{5}$');
  static final RegExp _ikpu = RegExp(r'^\d{17}$');

  Future<BarcodeOwner?> ownerOf(String barcode) async {
    final code = Barcodes.normalize(barcode);
    if (code == null) return null;
    final row = await _db
        .customSelect(
          'SELECT p.id, p.name FROM product_barcodes b '
          'JOIN products p ON p.id = b.product_id '
          'WHERE b.barcode = ? AND p.deleted_at IS NULL',
          variables: [Variable.withString(code)],
          readsFrom: {_db.productBarcodes, _db.products},
        )
        .getSingleOrNull();
    if (row == null) return null;
    return BarcodeOwner(
      productId: row.read<String>('id'),
      productName: row.read<String>('name'),
    );
  }

  /// Tahrirlash uchun mavjud tovar.
  Future<ProductDraft?> load(String id) async {
    final p = await (_db.select(
      _db.products,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (p == null) return null;
    final codes =
        await (_db.select(_db.productBarcodes)
              ..where((b) => b.productId.equals(id))
              ..orderBy([
                (b) => OrderingTerm.desc(b.isPrimary),
                (b) => OrderingTerm.asc(b.barcode),
              ]))
            .get();
    return ProductDraft(
      id: p.id,
      name: p.name,
      categoryId: p.categoryId,
      unitId: p.unitId,
      sellPriceTiyin: p.sellPriceTiyin,
      costPriceTiyin: p.costPriceTiyin,
      isWeighted: p.isWeighted,
      pluCode: p.pluCode ?? '',
      minStockMilli: p.minStockMilli,
      ikpuCode: p.ikpuCode ?? '',
      quickButton: p.quickButton,
      isActive: p.isActive,
      barcodes: [for (final b in codes) b.barcode],
    );
  }

  Future<List<ProductProblem>> validate(ProductDraft d) async {
    final problems = <ProductProblem>[];
    if (d.name.trim().isEmpty) {
      problems.add(
        const ProductProblem(ProductField.name, ProductProblemCode.required),
      );
    }
    final unit = d.unitId == null
        ? null
        : await (_db.select(
            _db.units,
          )..where((u) => u.id.equals(d.unitId!))).getSingleOrNull();
    if (unit == null) {
      problems.add(
        const ProductProblem(ProductField.unit, ProductProblemCode.required),
      );
    } else if (d.isWeighted && !unit.isFractional) {
      problems.add(
        const ProductProblem(
          ProductField.unit,
          ProductProblemCode.weightedNeedsFractionalUnit,
        ),
      );
    }
    if (d.sellPriceTiyin <= 0) {
      problems.add(
        const ProductProblem(
          ProductField.price,
          ProductProblemCode.notPositive,
        ),
      );
    }

    final seen = <String>{};
    for (final raw in d.barcodes) {
      final check = Barcodes.check(raw);
      final code = raw.trim();
      if (check == BarcodeCheck.invalidFormat) {
        problems.add(
          ProductProblem(
            ProductField.barcodes,
            ProductProblemCode.barcodeFormat,
            barcode: code,
          ),
        );
        continue;
      }
      if (check == BarcodeCheck.invalidCheckDigit) {
        problems.add(
          ProductProblem(
            ProductField.barcodes,
            ProductProblemCode.barcodeCheckDigit,
            barcode: code,
          ),
        );
        continue;
      }
      if (!seen.add(code)) {
        problems.add(
          ProductProblem(
            ProductField.barcodes,
            ProductProblemCode.barcodeRepeated,
            barcode: code,
          ),
        );
        continue;
      }
      final owner = await ownerOf(code);
      if (owner != null && owner.productId != d.id) {
        problems.add(
          ProductProblem(
            ProductField.barcodes,
            ProductProblemCode.barcodeTaken,
            barcode: code,
            otherProduct: owner.productName,
          ),
        );
      }
    }

    final plu = d.pluCode.trim();
    if (plu.isNotEmpty) {
      if (!_plu.hasMatch(plu)) {
        problems.add(
          const ProductProblem(ProductField.plu, ProductProblemCode.pluFormat),
        );
      } else if (d.isActive) {
        final other =
            await (_db.select(_db.products)..where(
                  (p) =>
                      p.pluCode.equals(plu) &
                      p.isActive.equals(true) &
                      p.deletedAt.isNull() &
                      (d.id == null
                          ? const Constant(true)
                          : p.id.equals(d.id!).not()),
                ))
                .getSingleOrNull();
        if (other != null) {
          problems.add(
            ProductProblem(
              ProductField.plu,
              ProductProblemCode.pluTaken,
              otherProduct: other.name,
            ),
          );
        }
      }
    }
    final ikpu = d.ikpuCode.trim();
    if (ikpu.isNotEmpty && !_ikpu.hasMatch(ikpu)) {
      problems.add(
        const ProductProblem(ProductField.ikpu, ProductProblemCode.ikpuFormat),
      );
    }
    return problems;
  }

  /// Saqlaydi va tovar ID sini qaytaradi; [by] — menejer yoki ega.
  Future<String> save(ProductDraft d, {required String by}) async {
    final problems = await validate(d);
    if (problems.isNotEmpty) throw InvalidProductException(problems);
    final id = d.id ?? _newId();
    final now = _now();
    final name = d.name.trim();
    final plu = d.pluCode.trim();
    final ikpu = d.ikpuCode.trim();
    final barcodes = [for (final b in d.barcodes) b.trim()];
    await _db.transaction(() async {
      await _db
          .into(_db.products)
          .insertOnConflictUpdate(
            ProductsCompanion.insert(
              id: id,
              name: name,
              searchKey: Value(SearchKey.of(name)),
              categoryId: Value(d.categoryId),
              unitId: d.unitId!,
              sellPriceTiyin: d.sellPriceTiyin,
              costPriceTiyin: Value(d.costPriceTiyin),
              isWeighted: Value(d.isWeighted),
              pluCode: Value(plu.isEmpty ? null : plu),
              minStockMilli: Value(d.minStockMilli),
              ikpuCode: Value(ikpu.isEmpty ? null : ikpu),
              quickButton: Value(d.quickButton),
              isActive: Value(d.isActive),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ),
          );
      await (_db.delete(
        _db.productBarcodes,
      )..where((b) => b.productId.equals(id))).go();
      for (final (i, code) in barcodes.indexed) {
        await _db
            .into(_db.productBarcodes)
            .insert(
              ProductBarcodesCompanion.insert(
                barcode: code,
                productId: id,
                isPrimary: Value(i == 0),
              ),
            );
      }
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.productUpserted,
        createdAt: now,
        payload: {
          'id': id,
          'name': name,
          'category': d.categoryId,
          'unit': d.unitId,
          'sell_price_tiyin': d.sellPriceTiyin,
          'cost_price_tiyin': d.costPriceTiyin,
          'is_weighted': d.isWeighted,
          'plu_code': plu.isEmpty ? null : plu,
          'min_stock_milli': d.minStockMilli,
          'ikpu_code': ikpu,
          'quick_button': d.quickButton,
          'is_active': d.isActive,
          'barcodes': barcodes,
          'by': by,
        },
      );
    });
    return id;
  }
}

final productEditorProvider = Provider<ProductEditor>(
  (ref) => ProductEditor(ref.watch(appDatabaseProvider)),
);

/// Kassadagi qoldiq (`sync.md`): serverdan kelgan oxirgi qiymat + hali
/// yuborilmagan lokal harakatlar (savdo, qaytarish, kirim).
Selectable<MapEntry<String, int>> stockQuery(AppDatabase db) => db
    .customSelect(
      'SELECT p.id AS id, COALESCE(ps.qty_milli, 0) + COALESCE( ( '
      'SELECT SUM(m.qty_milli) FROM stock_movements m '
      'LEFT JOIN outbox_events e ON e.id = m.outbox_event_id '
      "WHERE m.product_id = p.id AND (e.status IS NULL OR e.status != 'sent')"
      ' ), 0) AS qty FROM products p '
      'LEFT JOIN product_stock ps ON ps.product_id = p.id '
      'WHERE p.deleted_at IS NULL',
      readsFrom: {
        db.products,
        db.productStock,
        db.stockMovements,
        db.outboxEvents,
      },
    )
    .map((r) => MapEntry(r.read<String>('id'), r.read<int>('qty')));

final stockByProductProvider = StreamProvider<Map<String, int>>(
  (ref) => stockQuery(
    ref.watch(appDatabaseProvider),
  ).watch().map(Map.fromEntries),
);
