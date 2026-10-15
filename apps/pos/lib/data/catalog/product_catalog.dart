import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/barcode/barcode.dart';
import 'package:pos_app/core/text/search_key.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Kassa uchun tovar (lokal bazadan, o'qish uchun).
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.priceTiyin,
    required this.costTiyin,
    required this.unit,
    this.isWeighted = false,
    this.isActive = true,
    this.quickButton = false,
    this.categoryId,
    this.pluCode,
    this.barcodes = const [],
    this.imageId,
  });

  final String id;

  /// Rasm (T-105): lokal fayl `product_images`.
  final String? imageId;
  final String name;
  final int priceTiyin;
  final int costTiyin;

  /// Birlik qisqa nomi (`kg`, `dona`) — miqdor yonida.
  final String unit;
  final bool isWeighted;
  final bool isActive;
  final bool quickButton;
  final String? categoryId;
  final String? pluCode;

  /// Birinchisi — asosiy.
  final List<String> barcodes;

  String? get primaryBarcode => barcodes.isEmpty ? null : barcodes.first;

  /// Savatga qo'shib bo'ladimi (nofaol yoki narxi 0 — yo'q, `barcode.md`).
  bool get sellable => isActive && priceTiyin > 0;
}

/// Skanerlangan kod natijasi.
class CodeMatch {
  const CodeMatch({
    required this.product,
    required this.code,
    this.qtyMilli,
    this.priceTiyin,
  });

  final CatalogProduct product;
  final String code;

  /// Tarozi kodidagi vazn.
  final int? qtyMilli;

  /// Tarozi kodidagi narx (narx turidagi format).
  final int? priceTiyin;

  bool get weighted => qtyMilli != null || priceTiyin != null;
}

class QuickCategory {
  const QuickCategory({required this.id, required this.name});

  final String id;
  final String name;
}

/// Tovarlar indeksi xotirada: skanerdan savatgacha ≤ 100 ms va har belgida
/// qidiruv ≤ 50 ms (3000–10 000 tovar) — `docs/specs/pos-screen.md`.
/// Baza o'zgarsa (pull) qayta yuklanadi: [productCatalogProvider].
class ProductCatalog {
  ProductCatalog(
    Iterable<CatalogProduct> products, {
    List<QuickCategory> categories = const [],
    this.weighted = const WeightedBarcodeFormat(),
  }) {
    final quickIds = <String?>{};
    for (final p in products) {
      final entry = _Entry(p, SearchKey.of(p.name));
      _byId[p.id] = p;
      for (final code in p.barcodes) {
        _byBarcode[code] = p;
      }
      if (p.pluCode != null) _byPlu[p.pluCode!] = p;
      if (p.isActive) {
        _entries.add(entry);
        if (p.quickButton) {
          _quick.add(p);
          quickIds.add(p.categoryId);
        }
      }
    }
    _entries.sort((a, b) => a.key.compareTo(b.key));
    _quick.sort((a, b) => SearchKey.of(a.name).compareTo(SearchKey.of(b.name)));
    quickCategories = [
      for (final c in categories)
        if (quickIds.contains(c.id)) c,
    ];
  }

  final WeightedBarcodeFormat weighted;

  /// Tez tugmasi bor tovarlar kategoriyalari (sozlangan tartibda).
  late final List<QuickCategory> quickCategories;

  final List<_Entry> _entries = [];
  final Map<String, CatalogProduct> _byId = {};
  final Map<String, CatalogProduct> _byBarcode = {};
  final Map<String, CatalogProduct> _byPlu = {};
  final List<CatalogProduct> _quick = [];

  int get length => _byId.length;

  CatalogProduct? byId(String id) => _byId[id];

  /// Shtrix-kod (yoki tarozi kodi → PLU) bo'yicha. Nofaol tovar ham
  /// qaytadi — ekran ogohlantiradi ([CatalogProduct.sellable]).
  CodeMatch? byCode(String raw) {
    final code = raw.trim();
    final direct = _byBarcode[code];
    if (direct != null) return CodeMatch(product: direct, code: code);
    final scale = weighted.parse(code);
    if (scale == null) return null;
    final product = _byPlu[scale.plu];
    if (product == null) return null;
    return CodeMatch(
      product: product,
      code: code,
      qtyMilli: scale.qtyMilli,
      priceTiyin: scale.priceTiyin,
    );
  }

  /// Nom (lotin/kirill farqsiz, so'zlar istalgan tartibda), shtrix-kod boshi
  /// va PLU bo'yicha. Tartib: aniq kod → nom boshidan → so'z boshidan →
  /// ichida; keyin alifbo.
  List<CatalogProduct> search(String query, {int limit = 50}) {
    final key = SearchKey.of(query);
    if (key.isEmpty) return const [];
    final tokens = key.split(' ');
    final digits = RegExp(r'^\d+$').hasMatch(key);
    final ranked = <(int, int, CatalogProduct)>[];
    for (final (i, e) in _entries.indexed) {
      final rank = _rank(e, key, tokens, digits);
      if (rank != null) ranked.add((rank, i, e.product));
    }
    // Teng darajada — alifbo (`_entries` tartibi).
    ranked.sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    return [for (final (_, _, p) in ranked.take(limit)) p];
  }

  int? _rank(_Entry e, String key, List<String> tokens, bool digits) {
    final p = e.product;
    if (digits) {
      if (p.pluCode == key || p.barcodes.contains(key)) return 0;
      if (key.length >= 3 && p.barcodes.any((b) => b.startsWith(key))) {
        return 1;
      }
    }
    if (e.key.startsWith(key)) return 2;
    if (!tokens.every(e.key.contains)) return null;
    final words = e.key.split(' ');
    if (tokens.every((t) => words.any((w) => w.startsWith(t)))) return 3;
    return 4;
  }

  /// Tez tugmalar paneli: kategoriya bo'yicha (`null` — hammasi).
  List<CatalogProduct> quick({String? categoryId}) => categoryId == null
      ? _quick
      : [
          for (final p in _quick)
            if (p.categoryId == categoryId) p,
        ];

  /// Lokal bazadan (o'chirilganlarsiz).
  static Future<ProductCatalog> load(
    AppDatabase db, {
    WeightedBarcodeFormat weighted = const WeightedBarcodeFormat(),
  }) async {
    final units = {
      for (final u in await db.select(db.units).get()) u.id: u.code,
    };
    final barcodes = <String, List<String>>{};
    final codes =
        await (db.select(db.productBarcodes)..orderBy([
              (b) => OrderingTerm.desc(b.isPrimary),
              (b) => OrderingTerm.asc(b.barcode),
            ]))
            .get();
    for (final b in codes) {
      barcodes.putIfAbsent(b.productId, () => []).add(b.barcode);
    }
    final rows = await (db.select(
      db.products,
    )..where((p) => p.deletedAt.isNull())).get();
    final categories =
        await (db.select(db.categories)
              ..where((c) => c.deletedAt.isNull())
              ..orderBy([
                (c) => OrderingTerm.asc(c.sort),
                (c) => OrderingTerm.asc(c.name),
              ]))
            .get();
    return ProductCatalog(
      [
        for (final r in rows)
          CatalogProduct(
            id: r.id,
            name: r.name,
            priceTiyin: r.sellPriceTiyin,
            costTiyin: r.costPriceTiyin,
            unit: units[r.unitId] ?? '',
            isWeighted: r.isWeighted,
            isActive: r.isActive,
            quickButton: r.quickButton,
            categoryId: r.categoryId,
            pluCode: r.pluCode,
            barcodes: barcodes[r.id] ?? const [],
            imageId: r.imageId,
          ),
      ],
      categories: [
        for (final c in categories) QuickCategory(id: c.id, name: c.name),
      ],
      weighted: weighted,
    );
  }
}

class _Entry {
  _Entry(this.product, this.key);

  final CatalogProduct product;
  final String key;
}

/// Katalog indeksi; tovarlar, shtrix-kodlar, birliklar yoki kategoriyalar
/// o'zgarsa (pull) qayta quriladi.
final productCatalogProvider = StreamProvider<ProductCatalog>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  yield await ProductCatalog.load(db);
  await for (final _ in db.tableUpdates(
    TableUpdateQuery.onAllTables([
      db.products,
      db.productBarcodes,
      db.units,
      db.categories,
    ]),
  )) {
    yield await ProductCatalog.load(db);
  }
});
