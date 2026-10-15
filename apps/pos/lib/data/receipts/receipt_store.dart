import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/core/money/money.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/sync/outbox.dart';

/// Kirim qatori: tovar, miqdor, tannarx va (o'zgartirilsa) yangi sotish narxi.
class ReceiptLine {
  const ReceiptLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.unit,
    required this.qtyMilli,
    required this.costTiyin,
    required this.currentSellTiyin,
    this.newSellTiyin,
  });

  final String id;
  final String productId;
  final String name;
  final UnitCode unit;
  final int qtyMilli;
  final int costTiyin;

  /// Tovarning hozirgi sotish narxi.
  final int currentSellTiyin;

  /// `null` — narx o'zgarmaydi.
  final int? newSellTiyin;

  int get sellTiyin => newSellTiyin ?? currentSellTiyin;
  int get totalTiyin => Money.lineTotal(costTiyin, qtyMilli);

  /// Sotish narxi tannarxdan past — sariq ogohlantirish (bloklamaydi).
  bool get sellBelowCost => sellTiyin < costTiyin;
}

class ReceiptDoc {
  const ReceiptDoc({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.lines,
    this.supplierId,
    this.supplierName,
    this.note = '',
    this.postedAt,
    this.correctsId,
    this.correctedById,
    this.correctionDraftId,
    this.cancelled = false,
  });

  final String id;

  /// `draft` / `posted`.
  final String status;
  final DateTime createdAt;
  final DateTime? postedAt;
  final String? supplierId;
  final String? supplierName;
  final String note;
  final List<ReceiptLine> lines;

  /// Tuzatish (T-102): bu hujjat qaysi kirimning yangi versiyasi.
  final String? correctsId;

  /// Bu kirimni almashtirgan (tasdiqlangan) yangi versiya.
  final String? correctedById;

  /// Shu kirimning hali tasdiqlanmagan tuzatish qoralamasi.
  final String? correctionDraftId;

  /// Bekor qilingan (teskari yozuv bor, yangi versiyasiz).
  final bool cancelled;

  bool get isDraft => status == 'draft';
  bool get isCorrection => correctsId != null;
  bool get isCorrected => correctedById != null;

  /// Tahrirlash yoki bekor qilish mumkin: tasdiqlangan, amaldagi versiya.
  bool get isActiveVersion => !isDraft && !isCorrected && !cancelled;
  int get totalCostTiyin => lines.fold(0, (s, l) => s + l.totalTiyin);
}

/// Ro'yxatdagi holat belgisi.
enum ReceiptState { draft, posted, corrected, cancelled }

class ReceiptSummary {
  const ReceiptSummary({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.lineCount,
    required this.totalCostTiyin,
    this.postedAt,
    this.supplierName,
    this.state = ReceiptState.posted,
    this.isCorrection = false,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final DateTime? postedAt;
  final String? supplierName;
  final int lineCount;
  final int totalCostTiyin;
  final ReceiptState state;

  /// Boshqa kirimning tuzatilgan versiyasi (yoki uning qoralamasi).
  final bool isCorrection;

  bool get isDraft => status == 'draft';
}

class SupplierEntry {
  const SupplierEntry({required this.id, required this.name, this.phone = ''});

  final String id;
  final String name;
  final String phone;
}

/// Bo'sh kirimni tasdiqlab bo'lmaydi (`receipt_empty`).
class ReceiptEmptyException implements Exception {
  const ReceiptEmptyException();
}

/// Kirimni tahrirlab/bekor qilib bo'lmaydi: qoralama, allaqachon tuzatilgan
/// yoki bekor qilingan, yoki teskari yozuv.
class ReceiptNotEditableException implements Exception {
  const ReceiptNotEditableException();
}

/// Kirim (`docs/specs/stock-receipt.md`): qoralama lokal bazada (har
/// o'zgarish darhol yoziladi — ilova yopilsa ham yo'qolmaydi), tasdiqlash —
/// bitta tranzaksiya: holat, qoldiq harakatlari (+), tovar narxlari, outbox
/// `receipt.posted`. Oflaynda ham ishlaydi.
class ReceiptStore {
  ReceiptStore(this._db, {IdGenerator? newId, DateTime Function()? now})
    : _newId = newId ?? _defaultId,
      _now = now ?? _clockNow;

  static String _defaultId() => newId();
  static DateTime _clockNow() => clock.now();

  final AppDatabase _db;
  final IdGenerator _newId;
  final DateTime Function() _now;

  Future<String> create() async {
    final id = _newId();
    await _db
        .into(_db.stockReceipts)
        .insert(StockReceiptsCompanion.insert(id: id, createdAt: _now()));
    return id;
  }

  /// Ro'yxat: teskari yozuvlar (bekor qilish hujjatlari) ko'rsatilmaydi —
  /// ularning ta'siri asl kirimdagi "Bekor qilingan"/"Tuzatilgan" belgisida.
  Stream<List<ReceiptSummary>> watchAll() => _db
      .customSelect(
        'SELECT r.id, r.status, r.created_at, r.posted_at, s.name AS supplier, '
        'COUNT(i.id) AS lines, r.total_cost_tiyin, r.corrects_id, '
        'EXISTS(SELECT 1 FROM stock_receipts c WHERE c.corrects_id = r.id '
        "AND c.status = 'posted') AS corrected, "
        'EXISTS(SELECT 1 FROM stock_receipts x WHERE x.reverses_id = r.id) '
        'AS reversed FROM stock_receipts r '
        'LEFT JOIN suppliers s ON s.id = r.supplier_id '
        'LEFT JOIN stock_receipt_items i ON i.receipt_id = r.id '
        'WHERE r.reverses_id IS NULL '
        "GROUP BY r.id ORDER BY r.status = 'posted', "
        'COALESCE(r.posted_at, r.created_at) DESC, r.created_at DESC',
        readsFrom: {_db.stockReceipts, _db.stockReceiptItems, _db.suppliers},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            ReceiptSummary(
              id: r.read<String>('id'),
              status: r.read<String>('status'),
              createdAt: r.read<DateTime>('created_at'),
              postedAt: r.readNullable<DateTime>('posted_at'),
              supplierName: r.readNullable<String>('supplier'),
              lineCount: r.read<int>('lines'),
              totalCostTiyin: r.read<int>('total_cost_tiyin'),
              isCorrection: r.readNullable<String>('corrects_id') != null,
              state: _state(
                r.read<String>('status'),
                corrected: r.read<bool>('corrected'),
                reversed: r.read<bool>('reversed'),
              ),
            ),
        ],
      );

  static ReceiptState _state(
    String status, {
    required bool corrected,
    required bool reversed,
  }) {
    if (status == 'draft') return ReceiptState.draft;
    if (corrected) return ReceiptState.corrected;
    if (reversed) return ReceiptState.cancelled;
    return ReceiptState.posted;
  }

  Selectable<ReceiptLine> _lines(String receiptId) => _db
      .customSelect(
        'SELECT i.id, i.product_id, p.name, u.code AS unit, i.qty_milli, '
        'i.cost_price_tiyin, i.new_sell_price_tiyin, p.sell_price_tiyin '
        'FROM stock_receipt_items i JOIN products p ON p.id = i.product_id '
        'LEFT JOIN units u ON u.id = p.unit_id '
        'WHERE i.receipt_id = ? ORDER BY i.position',
        variables: [Variable.withString(receiptId)],
        readsFrom: {_db.stockReceiptItems, _db.products, _db.units},
      )
      .map(
        (r) => ReceiptLine(
          id: r.read<String>('id'),
          productId: r.read<String>('product_id'),
          name: r.read<String>('name'),
          unit: UnitCode.fromCode(r.readNullable<String>('unit')),
          qtyMilli: r.read<int>('qty_milli'),
          costTiyin: r.read<int>('cost_price_tiyin'),
          newSellTiyin: r.readNullable<int>('new_sell_price_tiyin'),
          currentSellTiyin: r.read<int>('sell_price_tiyin'),
        ),
      );

  Future<ReceiptDoc?> load(String id) async {
    final r = await (_db.select(
      _db.stockReceipts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) return null;
    final supplier = r.supplierId == null
        ? null
        : await (_db.select(
            _db.suppliers,
          )..where((s) => s.id.equals(r.supplierId!))).getSingleOrNull();
    final children = await (_db.select(
      _db.stockReceipts,
    )..where((c) => c.correctsId.equals(id) | c.reversesId.equals(id))).get();
    String? correctedBy;
    String? draft;
    var reversed = false;
    for (final c in children) {
      if (c.reversesId == id) {
        reversed = true;
      } else if (c.status == 'posted') {
        correctedBy = c.id;
      } else {
        draft = c.id;
      }
    }
    return ReceiptDoc(
      id: r.id,
      status: r.status,
      createdAt: r.createdAt,
      postedAt: r.postedAt,
      supplierId: r.supplierId,
      supplierName: supplier?.name,
      note: r.note,
      lines: await _lines(id).get(),
      correctsId: r.correctsId,
      correctedById: correctedBy,
      correctionDraftId: draft,
      cancelled: reversed && correctedBy == null,
    );
  }

  /// Kirim va qatorlari o'zgarganda yangilanadi.
  Stream<ReceiptDoc?> watch(String id) => _db
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          _db.stockReceipts,
          _db.stockReceiptItems,
          _db.products,
          _db.suppliers,
        ]),
      )
      .asyncMap((_) => load(id))
      .startWith(load(id));

  /// Skan yoki qidiruv: shu tovar qatori bo'lsa — miqdor qo'shiladi, yo'q
  /// bo'lsa — yangi qator (oxirgi tannarx bilan).
  Future<void> addProduct(
    String receiptId,
    String productId, {
    int qtyMilli = 1000,
  }) => _db.transaction(() async {
    // `.get()` — server/import kirimida bir tovar bir necha qatorda bo'lishi
    // mumkin; `getSingleOrNull` bunda xato tashlardi (audit RC-B14).
    final existing =
        (await (_db.select(_db.stockReceiptItems)..where(
                  (i) =>
                      i.receiptId.equals(receiptId) &
                      i.productId.equals(productId),
                ))
                .get())
            .firstOrNull;
    if (existing != null) {
      await (_db.update(
        _db.stockReceiptItems,
      )..where((i) => i.id.equals(existing.id))).write(
        StockReceiptItemsCompanion(
          qtyMilli: Value(existing.qtyMilli + qtyMilli),
        ),
      );
    } else {
      final product = await (_db.select(
        _db.products,
      )..where((p) => p.id.equals(productId))).getSingle();
      final count = await _count(receiptId);
      await _db
          .into(_db.stockReceiptItems)
          .insert(
            StockReceiptItemsCompanion.insert(
              id: _newId(),
              receiptId: receiptId,
              position: count,
              productId: productId,
              qtyMilli: qtyMilli,
              costPriceTiyin: product.costPriceTiyin,
            ),
          );
    }
    await _recalc(receiptId);
  });

  Future<int> _count(String receiptId) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(position) + 1, 0) AS n FROM stock_receipt_items '
          'WHERE receipt_id = ?',
          variables: [Variable.withString(receiptId)],
          readsFrom: {_db.stockReceiptItems},
        )
        .getSingle();
    return row.read<int>('n');
  }

  Future<void> _updateLine(
    String lineId,
    StockReceiptItemsCompanion change,
  ) => _db.transaction(() async {
    final line = await (_db.select(
      _db.stockReceiptItems,
    )..where((i) => i.id.equals(lineId))).getSingle();
    await (_db.update(
      _db.stockReceiptItems,
    )..where((i) => i.id.equals(lineId))).write(change);
    await _recalc(line.receiptId);
  });

  Future<void> setQty(String lineId, int qtyMilli) {
    if (qtyMilli <= 0) throw ArgumentError.value(qtyMilli, 'qtyMilli');
    return _updateLine(
      lineId,
      StockReceiptItemsCompanion(qtyMilli: Value(qtyMilli)),
    );
  }

  Future<void> setCost(String lineId, int costTiyin) {
    if (costTiyin < 0) throw ArgumentError.value(costTiyin, 'costTiyin');
    return _updateLine(
      lineId,
      StockReceiptItemsCompanion(costPriceTiyin: Value(costTiyin)),
    );
  }

  /// Hozirgi narxga teng bo'lsa — narx o'zgarmaydi (`null`).
  Future<void> setSellPrice(String lineId, int sellTiyin) async {
    if (sellTiyin <= 0) throw ArgumentError.value(sellTiyin, 'sellTiyin');
    final row = await _db
        .customSelect(
          'SELECT p.sell_price_tiyin FROM stock_receipt_items i '
          'JOIN products p ON p.id = i.product_id WHERE i.id = ?',
          variables: [Variable.withString(lineId)],
        )
        .getSingle();
    final current = row.read<int>('sell_price_tiyin');
    await _updateLine(
      lineId,
      StockReceiptItemsCompanion(
        newSellPriceTiyin: Value(sellTiyin == current ? null : sellTiyin),
      ),
    );
  }

  Future<void> removeLine(String lineId) => _db.transaction(() async {
    final line = await (_db.select(
      _db.stockReceiptItems,
    )..where((i) => i.id.equals(lineId))).getSingleOrNull();
    if (line == null) return;
    await (_db.delete(
      _db.stockReceiptItems,
    )..where((i) => i.id.equals(lineId))).go();
    await _recalc(line.receiptId);
  });

  Future<void> setSupplier(String receiptId, String? supplierId) =>
      (_db.update(_db.stockReceipts)..where((r) => r.id.equals(receiptId)))
          .write(StockReceiptsCompanion(supplierId: Value(supplierId)));

  Future<void> setNote(String receiptId, String note) =>
      (_db.update(_db.stockReceipts)..where((r) => r.id.equals(receiptId)))
          .write(StockReceiptsCompanion(note: Value(note)));

  /// Qoralamani o'chirish (tasdiqlangan kirim o'zgarmaydi).
  Future<void> deleteDraft(String receiptId) => _db.transaction(() async {
    final r = await (_db.select(
      _db.stockReceipts,
    )..where((t) => t.id.equals(receiptId))).getSingleOrNull();
    if (r == null || r.status != 'draft') return;
    await (_db.delete(
      _db.stockReceiptItems,
    )..where((i) => i.receiptId.equals(receiptId))).go();
    await (_db.delete(
      _db.stockReceipts,
    )..where((t) => t.id.equals(receiptId))).go();
  });

  Future<void> _recalc(String receiptId) async {
    final lines = await (_db.select(
      _db.stockReceiptItems,
    )..where((i) => i.receiptId.equals(receiptId))).get();
    final total = lines.fold(
      0,
      (s, l) => s + Money.lineTotal(l.costPriceTiyin, l.qtyMilli),
    );
    await (_db.update(_db.stockReceipts)..where((r) => r.id.equals(receiptId)))
        .write(StockReceiptsCompanion(totalCostTiyin: Value(total)));
  }

  /// Tasdiqlash — bitta tranzaksiya; [by] — ega yoki menejer.
  Future<void> post(String receiptId, {required String by, String? storeId}) =>
      _db.transaction(() async {
        final receipt = await (_db.select(
          _db.stockReceipts,
        )..where((r) => r.id.equals(receiptId))).getSingle();
        if (receipt.status != 'draft') return;
        final items =
            await (_db.select(_db.stockReceiptItems)
                  ..where((i) => i.receiptId.equals(receiptId))
                  ..orderBy([(i) => OrderingTerm.asc(i.position)]))
                .get();
        if (items.isEmpty) throw const ReceiptEmptyException();
        final now = _now();
        final eventId = _newId();
        for (final item in items) {
          await _db
              .into(_db.stockMovements)
              .insert(
                StockMovementsCompanion.insert(
                  id: _newId(),
                  productId: item.productId,
                  storeId: Value(storeId),
                  qtyMilli: item.qtyMilli,
                  type: 'receipt',
                  refType: 'stock_receipt',
                  refId: receiptId,
                  outboxEventId: Value(eventId),
                  at: now,
                ),
              );
          // Server ham shunday qiladi: tannarx — qatornikiga, narx — berilsa.
          await (_db.update(
            _db.products,
          )..where((p) => p.id.equals(item.productId))).write(
            ProductsCompanion(
              costPriceTiyin: Value(item.costPriceTiyin),
              sellPriceTiyin: item.newSellPriceTiyin == null
                  ? const Value.absent()
                  : Value(item.newSellPriceTiyin!),
              updatedAt: Value(now),
            ),
          );
        }
        await (_db.update(
          _db.stockReceipts,
        )..where((r) => r.id.equals(receiptId))).write(
          StockReceiptsCompanion(
            status: const Value('posted'),
            postedAt: Value(now),
            postedBy: Value(by),
            storeId: Value(storeId),
          ),
        );
        await _db.enqueueEvent(
          id: eventId,
          type: OutboxEventType.receiptPosted,
          createdAt: now,
          payload: {
            'id': receiptId,
            'supplier': receipt.supplierId,
            'note': receipt.note,
            'items': [
              for (final i in items)
                {
                  'product': i.productId,
                  'qty_milli': i.qtyMilli,
                  'cost_price_tiyin': i.costPriceTiyin,
                  'new_sell_price_tiyin': ?i.newSellPriceTiyin,
                },
            ],
            'by': by,
            'at': isoUtc(now),
          },
        );
      });

  // ---- Tuzatish va bekor qilish (T-102, stock-receipt.md) ---------------
  //
  // Tasdiqlangan kirim o'zgarmaydi (CLAUDE.md 3-qoida). Tahrirlash = asl
  // kirimni teskari yozuv bilan bekor qilish + yangi versiya, bitta
  // tranzaksiyada va bitta outbox hodisasida. Qoldiq: −eski + yangi
  // (10 → 7 = −10 + 7), har harakat bir marta hisoblanadi.

  Future<StockReceipt> _activeVersion(String receiptId) async {
    final r = await (_db.select(
      _db.stockReceipts,
    )..where((t) => t.id.equals(receiptId))).getSingleOrNull();
    if (r == null || r.status != 'posted' || r.reversesId != null) {
      throw const ReceiptNotEditableException();
    }
    final replaced =
        await (_db.select(_db.stockReceipts)..where(
              (c) =>
                  c.reversesId.equals(receiptId) |
                  (c.correctsId.equals(receiptId) & c.status.equals('posted')),
            ))
            .get();
    if (replaced.isNotEmpty) throw const ReceiptNotEditableException();
    return r;
  }

  /// Tuzatish qoralamasi: asl kirim nusxasi (bir tovar — bitta qator, yangi
  /// sotish narxisiz). Qoralama bor bo'lsa — o'sha qaytariladi. Qoralamani
  /// o'chirish tuzatishdan voz kechish (qoldiqqa ta'sirsiz).
  Future<String> startCorrection(String originalId) => _db.transaction(
    () async {
      final original = await _activeVersion(originalId);
      final draft =
          await (_db.select(_db.stockReceipts)..where(
                (c) =>
                    c.correctsId.equals(originalId) & c.status.equals('draft'),
              ))
              .getSingleOrNull();
      if (draft != null) return draft.id;
      final id = _newId();
      await _db
          .into(_db.stockReceipts)
          .insert(
            StockReceiptsCompanion.insert(
              id: id,
              createdAt: _now(),
              supplierId: Value(original.supplierId),
              note: Value(original.note),
              correctsId: Value(originalId),
            ),
          );
      final items =
          await (_db.select(_db.stockReceiptItems)
                ..where((i) => i.receiptId.equals(originalId))
                ..orderBy([(i) => OrderingTerm.asc(i.position)]))
              .get();
      final merged = <String, StockReceiptItem>{};
      for (final item in items) {
        final seen = merged[item.productId];
        merged[item.productId] = seen == null
            ? item
            : seen.copyWith(qtyMilli: seen.qtyMilli + item.qtyMilli);
      }
      var position = 0;
      for (final item in merged.values) {
        await _db
            .into(_db.stockReceiptItems)
            .insert(
              StockReceiptItemsCompanion.insert(
                id: _newId(),
                receiptId: id,
                position: position++,
                productId: item.productId,
                qtyMilli: item.qtyMilli,
                costPriceTiyin: item.costPriceTiyin,
              ),
            );
      }
      await _recalc(id);
      return id;
    },
  );

  /// Teskari yozuv: asl qatorlar manfiy, qoldiq harakatlari (−).
  Future<void> _writeReversal(
    StockReceipt original, {
    required String reversalId,
    required String eventId,
    required String by,
    required DateTime now,
    String? storeId,
  }) async {
    await _db
        .into(_db.stockReceipts)
        .insert(
          StockReceiptsCompanion.insert(
            id: reversalId,
            createdAt: now,
            supplierId: Value(original.supplierId),
            storeId: Value(storeId ?? original.storeId),
            status: const Value('posted'),
            totalCostTiyin: Value(-original.totalCostTiyin),
            postedAt: Value(now),
            postedBy: Value(by),
            reversesId: Value(original.id),
          ),
        );
    final items = await (_db.select(
      _db.stockReceiptItems,
    )..where((i) => i.receiptId.equals(original.id))).get();
    var position = 0;
    for (final item in items) {
      await _db
          .into(_db.stockReceiptItems)
          .insert(
            StockReceiptItemsCompanion.insert(
              id: _newId(),
              receiptId: reversalId,
              position: position++,
              productId: item.productId,
              qtyMilli: -item.qtyMilli,
              costPriceTiyin: item.costPriceTiyin,
            ),
          );
      await _db
          .into(_db.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: _newId(),
              productId: item.productId,
              storeId: Value(storeId ?? original.storeId),
              qtyMilli: -item.qtyMilli,
              type: 'receipt',
              refType: 'stock_receipt',
              refId: reversalId,
              outboxEventId: Value(eventId),
              at: now,
            ),
          );
    }
  }

  /// [since] dan keyin shu tovar bilan amaldagi boshqa kirim bormi (server
  /// qoidasi: eski kirimni tuzatish yangi kirim tannarxini bosmaydi).
  Future<bool> _newerReceiptExists(
    String productId,
    DateTime since,
    String exceptId,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT 1 FROM stock_receipt_items i '
          'JOIN stock_receipts r ON r.id = i.receipt_id '
          "WHERE i.product_id = ? AND r.status = 'posted' "
          'AND r.reverses_id IS NULL AND r.id <> ? AND r.posted_at > ? '
          'AND NOT EXISTS(SELECT 1 FROM stock_receipts x '
          'WHERE x.reverses_id = r.id) LIMIT 1',
          variables: [
            Variable.withString(productId),
            Variable.withString(exceptId),
            Variable.withDateTime(since),
          ],
          readsFrom: {_db.stockReceiptItems, _db.stockReceipts},
        )
        .getSingleOrNull();
    return row != null;
  }

  /// Tuzatishni tasdiqlash — bitta tranzaksiya: teskari yozuv, yangi
  /// versiya harakatlari, narxlar, bitta `receipt.corrected` hodisasi.
  /// Yangi versiya hujjat sanasi — asl kirimniki (server bilan bir xil).
  Future<void> postCorrection(
    String draftId, {
    required String by,
    String? storeId,
  }) => _db.transaction(() async {
    final draft = await (_db.select(
      _db.stockReceipts,
    )..where((r) => r.id.equals(draftId))).getSingle();
    final originalId = draft.correctsId;
    if (draft.status != 'draft' || originalId == null) {
      throw const ReceiptNotEditableException();
    }
    final original = await _activeVersion(originalId);
    final items =
        await (_db.select(_db.stockReceiptItems)
              ..where((i) => i.receiptId.equals(draftId))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();
    if (items.isEmpty) throw const ReceiptEmptyException();
    final now = _now();
    final eventId = _newId();
    final reversalId = _newId();
    await _writeReversal(
      original,
      reversalId: reversalId,
      eventId: eventId,
      by: by,
      now: now,
      storeId: storeId,
    );
    final documentAt = original.postedAt ?? now;
    for (final item in items) {
      await _db
          .into(_db.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: _newId(),
              productId: item.productId,
              storeId: Value(storeId ?? original.storeId),
              qtyMilli: item.qtyMilli,
              type: 'receipt',
              refType: 'stock_receipt',
              refId: draftId,
              outboxEventId: Value(eventId),
              at: now,
            ),
          );
      final updateCost = !await _newerReceiptExists(
        item.productId,
        documentAt,
        draftId,
      );
      if (updateCost || item.newSellPriceTiyin != null) {
        await (_db.update(
          _db.products,
        )..where((p) => p.id.equals(item.productId))).write(
          ProductsCompanion(
            costPriceTiyin: updateCost
                ? Value(item.costPriceTiyin)
                : const Value.absent(),
            sellPriceTiyin: item.newSellPriceTiyin == null
                ? const Value.absent()
                : Value(item.newSellPriceTiyin!),
            updatedAt: Value(now),
          ),
        );
      }
    }
    await (_db.update(
      _db.stockReceipts,
    )..where((r) => r.id.equals(draftId))).write(
      StockReceiptsCompanion(
        status: const Value('posted'),
        postedAt: Value(documentAt),
        postedBy: Value(by),
        storeId: Value(storeId ?? original.storeId),
      ),
    );
    await _db.enqueueEvent(
      id: eventId,
      type: OutboxEventType.receiptCorrected,
      createdAt: now,
      payload: {
        'id': draftId,
        'corrects': originalId,
        'reversal_id': reversalId,
        'supplier': draft.supplierId,
        'note': draft.note,
        'items': [
          for (final i in items)
            {
              'product': i.productId,
              'qty_milli': i.qtyMilli,
              'cost_price_tiyin': i.costPriceTiyin,
              'new_sell_price_tiyin': ?i.newSellPriceTiyin,
            },
        ],
        'by': by,
        'at': isoUtc(now),
      },
    );
  });

  /// Kirimni bekor qilish — teskari yozuv va `receipt.reversed` (bitta
  /// tranzaksiya). Narxlar o'zgarmaydi. Tuzatish qoralamasi bo'lsa o'chadi.
  Future<void> cancel(
    String receiptId, {
    required String by,
    String? storeId,
    String note = '',
  }) => _db.transaction(() async {
    final original = await _activeVersion(receiptId);
    final now = _now();
    final eventId = _newId();
    final reversalId = _newId();
    await _writeReversal(
      original,
      reversalId: reversalId,
      eventId: eventId,
      by: by,
      now: now,
      storeId: storeId,
    );
    final drafts =
        await (_db.select(_db.stockReceipts)..where(
              (c) => c.correctsId.equals(receiptId) & c.status.equals('draft'),
            ))
            .get();
    for (final d in drafts) {
      await (_db.delete(
        _db.stockReceiptItems,
      )..where((i) => i.receiptId.equals(d.id))).go();
      await (_db.delete(
        _db.stockReceipts,
      )..where((t) => t.id.equals(d.id))).go();
    }
    await _db.enqueueEvent(
      id: eventId,
      type: OutboxEventType.receiptReversed,
      createdAt: now,
      payload: {
        'id': reversalId,
        'reverses': receiptId,
        'note': note,
        'by': by,
        'at': isoUtc(now),
      },
    );
  });

  Stream<List<SupplierEntry>> watchSuppliers() =>
      (_db.select(_db.suppliers)
            ..where((s) => s.deletedAt.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .watch()
          .map(
            (rows) => [
              for (final s in rows)
                SupplierEntry(id: s.id, name: s.name, phone: s.phone),
            ],
          );

  /// Yetkazib beruvchini tez yaratish + `supplier.upserted` (ega/menejer).
  Future<String> createSupplier({
    required String name,
    required String by,
    String phone = '',
  }) async {
    final id = _newId();
    final now = _now();
    await _db.transaction(() async {
      await _db
          .into(_db.suppliers)
          .insert(
            SuppliersCompanion.insert(
              id: id,
              name: name.trim(),
              phone: Value(phone.trim()),
            ),
          );
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.supplierUpserted,
        createdAt: now,
        payload: {
          'id': id,
          'name': name.trim(),
          'phone': phone.trim(),
          'note': '',
          'by': by,
        },
      );
    });
    return id;
  }
}

extension<T> on Stream<T> {
  /// Birinchi qiymat — darhol (keyingilari jadval o'zgarganda).
  Stream<T> startWith(Future<T> first) async* {
    yield await first;
    yield* this;
  }
}

final receiptStoreProvider = Provider<ReceiptStore>(
  (ref) => ReceiptStore(ref.watch(appDatabaseProvider)),
);
