import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/sync/outbox.dart';

/// Inventarizatsiya qatori: sanalgan va tizimdagi (kutilgan) miqdor.
class CountLine {
  const CountLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.unit,
    required this.countedMilli,
    required this.expectedMilli,
  });

  final String id;
  final String productId;
  final String name;
  final UnitCode unit;
  final int countedMilli;

  /// Qoralamada — hozirgi lokal qoldiq; tasdiqlanganda — o'sha paytdagisi.
  final int expectedMilli;

  /// `sanalgan − tizimdagi`: musbat — ortiqcha, manfiy — kam.
  int get diffMilli => countedMilli - expectedMilli;
}

/// Qamrovdagi, lekin hali sanalmagan tovar.
class UncountedProduct {
  const UncountedProduct({
    required this.productId,
    required this.name,
    required this.unit,
    required this.stockMilli,
  });

  final String productId;
  final String name;
  final UnitCode unit;
  final int stockMilli;
}

class CountDoc {
  const CountDoc({
    required this.id,
    required this.status,
    required this.scope,
    required this.createdAt,
    required this.lines,
    required this.uncounted,
    this.categoryId,
    this.categoryName,
    this.note = '',
    this.postedAt,
  });

  final String id;
  final String status;

  /// `all` / `category`.
  final String scope;
  final String? categoryId;
  final String? categoryName;
  final String note;
  final DateTime createdAt;
  final DateTime? postedAt;
  final List<CountLine> lines;

  /// Faqat qoralamada (tasdiqlanganda — bo'sh).
  final List<UncountedProduct> uncounted;

  bool get isDraft => status == 'draft';
  int get surplusCount => lines.where((l) => l.diffMilli > 0).length;
  int get shortageCount => lines.where((l) => l.diffMilli < 0).length;
}

class CountSummary {
  const CountSummary({
    required this.id,
    required this.status,
    required this.scope,
    required this.createdAt,
    required this.lineCount,
    this.categoryName,
    this.postedAt,
  });

  final String id;
  final String status;
  final String scope;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime? postedAt;
  final int lineCount;

  bool get isDraft => status == 'draft';
}

/// Bo'sh inventarizatsiyani tasdiqlab bo'lmaydi (`count_empty`).
class CountEmptyException implements Exception {
  const CountEmptyException();
}

/// Inventarizatsiya (`inventory-api.md`): qoralama lokal bazada; tasdiqlash
/// — bitta tranzaksiya: har sanalgan tovar uchun tizimdagi miqdor yoziladi,
/// farq bo'lsa `inventory` harakati (qoldiq = sanalgan), outbox
/// `inventory.posted`. **Sanalmagan tovarlar o'zgarmaydi.**
class CountStore {
  CountStore(this._db, {IdGenerator? newId, DateTime Function()? now})
    : _newId = newId ?? _defaultId,
      _now = now ?? _clockNow;

  static String _defaultId() => newId();
  static DateTime _clockNow() => clock.now();

  final AppDatabase _db;
  final IdGenerator _newId;
  final DateTime Function() _now;

  Future<String> create({String? categoryId}) async {
    final id = _newId();
    await _db
        .into(_db.inventoryCounts)
        .insert(
          InventoryCountsCompanion.insert(
            id: id,
            createdAt: _now(),
            scope: Value(categoryId == null ? 'all' : 'category'),
            categoryId: Value(categoryId),
          ),
        );
    return id;
  }

  Stream<List<CountSummary>> watchAll() => _db
      .customSelect(
        'SELECT n.id, n.status, n.scope, n.created_at, n.posted_at, '
        'c.name AS category, COUNT(i.id) AS lines FROM inventory_counts n '
        'LEFT JOIN categories c ON c.id = n.category_id '
        'LEFT JOIN inventory_count_items i ON i.count_id = n.id '
        "GROUP BY n.id ORDER BY n.status = 'posted', "
        'COALESCE(n.posted_at, n.created_at) DESC',
        readsFrom: {
          _db.inventoryCounts,
          _db.inventoryCountItems,
          _db.categories,
        },
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            CountSummary(
              id: r.read<String>('id'),
              status: r.read<String>('status'),
              scope: r.read<String>('scope'),
              categoryName: r.readNullable<String>('category'),
              createdAt: r.read<DateTime>('created_at'),
              postedAt: r.readNullable<DateTime>('posted_at'),
              lineCount: r.read<int>('lines'),
            ),
        ],
      );

  Future<CountDoc?> load(String id) async {
    final n = await (_db.select(
      _db.inventoryCounts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (n == null) return null;
    final category = n.categoryId == null
        ? null
        : await (_db.select(
            _db.categories,
          )..where((c) => c.id.equals(n.categoryId!))).getSingleOrNull();
    final stock = Map.fromEntries(await stockQuery(_db).get());
    final units = {
      for (final u in await _db.select(_db.units).get()) u.id: u.code,
    };
    final rows = await _db
        .customSelect(
          'SELECT i.id, i.product_id, i.counted_milli, i.expected_milli, '
          'p.name, p.unit_id FROM inventory_count_items i '
          'JOIN products p ON p.id = i.product_id '
          // Qo'shilish tartibi (jadvalda tartib ustuni yo'q).
          'WHERE i.count_id = ? ORDER BY i.rowid',
          variables: [Variable.withString(id)],
          readsFrom: {_db.inventoryCountItems, _db.products},
        )
        .get();
    final draft = n.status == 'draft';
    final lines = [
      for (final r in rows)
        CountLine(
          id: r.read<String>('id'),
          productId: r.read<String>('product_id'),
          name: r.read<String>('name'),
          unit: UnitCode.fromCode(units[r.read<String>('unit_id')]),
          countedMilli: r.read<int>('counted_milli'),
          expectedMilli: draft
              ? stock[r.read<String>('product_id')] ?? 0
              : r.readNullable<int>('expected_milli') ?? 0,
        ),
    ];
    final counted = {for (final l in lines) l.productId};
    final uncounted = <UncountedProduct>[];
    if (draft) {
      final products =
          await (_db.select(_db.products)
                ..where(
                  (p) =>
                      p.deletedAt.isNull() &
                      p.isActive.equals(true) &
                      (n.categoryId == null
                          ? const Constant(true)
                          : p.categoryId.equals(n.categoryId!)),
                )
                ..orderBy([(p) => OrderingTerm.asc(p.name)]))
              .get();
      for (final p in products) {
        if (counted.contains(p.id)) continue;
        uncounted.add(
          UncountedProduct(
            productId: p.id,
            name: p.name,
            unit: UnitCode.fromCode(units[p.unitId]),
            stockMilli: stock[p.id] ?? 0,
          ),
        );
      }
    }
    return CountDoc(
      id: n.id,
      status: n.status,
      scope: n.scope,
      categoryId: n.categoryId,
      categoryName: category?.name,
      note: n.note,
      createdAt: n.createdAt,
      postedAt: n.postedAt,
      lines: lines,
      uncounted: uncounted,
    );
  }

  /// Hujjat, qatorlar yoki qoldiq o'zgarganda yangilanadi.
  Stream<CountDoc?> watch(String id) async* {
    yield await load(id);
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.inventoryCounts,
        _db.inventoryCountItems,
        _db.products,
        _db.productStock,
        _db.stockMovements,
      ]),
    )) {
      yield await load(id);
    }
  }

  /// Skan: sanalgan miqdorga qo'shadi (yangi qator — [qtyMilli] bilan).
  Future<void> addCounted(
    String countId,
    String productId, {
    int qtyMilli = 1000,
  }) => _db.transaction(() async {
    final existing =
        await (_db.select(_db.inventoryCountItems)..where(
              (i) => i.countId.equals(countId) & i.productId.equals(productId),
            ))
            .getSingleOrNull();
    if (existing != null) {
      await (_db.update(
        _db.inventoryCountItems,
      )..where((i) => i.id.equals(existing.id))).write(
        InventoryCountItemsCompanion(
          countedMilli: Value(existing.countedMilli + qtyMilli),
        ),
      );
      return;
    }
    await _db
        .into(_db.inventoryCountItems)
        .insert(
          InventoryCountItemsCompanion.insert(
            id: _newId(),
            countId: countId,
            productId: productId,
            countedMilli: qtyMilli,
          ),
        );
  });

  Future<void> setCounted(String lineId, int countedMilli) {
    if (countedMilli < 0) throw ArgumentError.value(countedMilli);
    return (_db.update(_db.inventoryCountItems)
          ..where((i) => i.id.equals(lineId)))
        .write(InventoryCountItemsCompanion(countedMilli: Value(countedMilli)));
  }

  Future<void> removeLine(String lineId) => (_db.delete(
    _db.inventoryCountItems,
  )..where((i) => i.id.equals(lineId))).go();

  Future<void> deleteDraft(String countId) => _db.transaction(() async {
    final n = await (_db.select(
      _db.inventoryCounts,
    )..where((t) => t.id.equals(countId))).getSingleOrNull();
    if (n == null || n.status != 'draft') return;
    await (_db.delete(
      _db.inventoryCountItems,
    )..where((i) => i.countId.equals(countId))).go();
    await (_db.delete(
      _db.inventoryCounts,
    )..where((t) => t.id.equals(countId))).go();
  });

  /// Tasdiqlash: qoldiq = sanalgan (sanalgan tovarlar uchun).
  Future<void> post(String countId, {required String by, String? storeId}) =>
      _db.transaction(() async {
        final n = await (_db.select(
          _db.inventoryCounts,
        )..where((t) => t.id.equals(countId))).getSingle();
        if (n.status != 'draft') return;
        final items =
            await (_db.select(_db.inventoryCountItems)
                  ..where((i) => i.countId.equals(countId))
                  ..orderBy([
                    (i) =>
                        OrderingTerm.asc(const CustomExpression<int>('rowid')),
                  ]))
                .get();
        if (items.isEmpty) throw const CountEmptyException();
        final stock = Map.fromEntries(await stockQuery(_db).get());
        final now = _now();
        final eventId = _newId();
        for (final item in items) {
          final expected = stock[item.productId] ?? 0;
          await (_db.update(
            _db.inventoryCountItems,
          )..where((i) => i.id.equals(item.id))).write(
            InventoryCountItemsCompanion(expectedMilli: Value(expected)),
          );
          final diff = item.countedMilli - expected;
          if (diff == 0) continue;
          await _db
              .into(_db.stockMovements)
              .insert(
                StockMovementsCompanion.insert(
                  id: _newId(),
                  productId: item.productId,
                  storeId: Value(storeId),
                  qtyMilli: diff,
                  type: 'inventory',
                  refType: 'inventory_count',
                  refId: countId,
                  outboxEventId: Value(eventId),
                  at: now,
                ),
              );
        }
        await (_db.update(
          _db.inventoryCounts,
        )..where((t) => t.id.equals(countId))).write(
          InventoryCountsCompanion(
            status: const Value('posted'),
            postedAt: Value(now),
            postedBy: Value(by),
            storeId: Value(storeId),
          ),
        );
        await _db.enqueueEvent(
          id: eventId,
          type: OutboxEventType.inventoryPosted,
          createdAt: now,
          payload: {
            'id': countId,
            'scope': n.scope,
            'category': n.categoryId,
            'note': n.note,
            'items': [
              for (final i in items)
                {'product': i.productId, 'counted_milli': i.countedMilli},
            ],
            'by': by,
          },
        );
      });
}

final countStoreProvider = Provider<CountStore>(
  (ref) => CountStore(ref.watch(appDatabaseProvider)),
);
