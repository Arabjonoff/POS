import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:pos_app/core/money/money.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/sync/outbox.dart';

enum SalePaymentMethod { cash, card, debt }

/// Savat qatori (yakunlangan savdo uchun).
class SaleLineInput {
  const SaleLineInput({
    required this.productId,
    required this.name,
    required this.qtyMilli,
    required this.priceTiyin,
    required this.costTiyin,
    this.barcode,
    this.discountTiyin = 0,
  });

  final String productId;
  final String name;
  final String? barcode;
  final int qtyMilli;
  final int priceTiyin;
  final int costTiyin;
  final int discountTiyin;

  /// `line_total(narx, miqdor) − chegirma` (server bilan bir xil yaxlitlash).
  int get totalTiyin => Money.lineTotal(priceTiyin, qtyMilli) - discountTiyin;
}

class SalePaymentInput {
  const SalePaymentInput.cash({
    required this.amountTiyin,
    required int this.receivedTiyin,
  }) : method = SalePaymentMethod.cash;

  const SalePaymentInput.card({required this.amountTiyin})
    : method = SalePaymentMethod.card,
      receivedTiyin = null;

  const SalePaymentInput.debt({required this.amountTiyin})
    : method = SalePaymentMethod.debt,
      receivedTiyin = null;

  final SalePaymentMethod method;
  final int amountTiyin;
  final int? receivedTiyin;

  int get changeTiyin =>
      receivedTiyin == null ? 0 : receivedTiyin! - amountTiyin;
}

class CompletedSaleInput {
  const CompletedSaleInput({
    required this.shiftId,
    required this.cashierId,
    required this.lines,
    required this.payments,
    this.storeId,
    this.customerId,
    this.approvedBy,
    this.discountTiyin = 0,
  });

  final String shiftId;
  final String cashierId;
  final String? storeId;
  final String? customerId;

  /// Menejer ruxsati (qarz limiti, narx o'zgarishi).
  final String? approvedBy;
  final List<SaleLineInput> lines;
  final List<SalePaymentInput> payments;

  /// Chek chegirmasi.
  final int discountTiyin;

  int get subtotalTiyin => lines.fold(0, (sum, l) => sum + l.totalTiyin);

  int get totalTiyin => subtotalTiyin - discountTiyin;
}

/// Savdo ma'lumoti noto'g'ri (server `invalid_sale` bilan bir xil qoidalar).
class InvalidSaleException implements Exception {
  const InvalidSaleException(this.reason);

  final String reason;

  @override
  String toString() => 'InvalidSaleException: $reason';
}

class RecordedSale {
  const RecordedSale({required this.id, required this.number});

  final String id;
  final String number;
}

/// Savdoni yakunlaydi: **bitta SQLite tranzaksiyasida** Sale + qatorlar +
/// to'lovlar + qoldiq harakatlari + (nasiya bo'lsa) qarz yozuvi + outbox
/// hodisasi `sale.completed` (`docs/specs/sync.md`, `sales-api.md`).
/// Biror qadam xato bersa — hech narsa yozilmaydi, chek raqami ham band
/// bo'lmaydi.
class SaleWriter {
  SaleWriter(
    this._db, {
    required this.deviceNumber,
    IdGenerator? newId,
    DateTime Function()? now,
  }) : _newId = newId ?? _defaultId,
       _now = now ?? _clockNow;

  static String _defaultId() => newId();

  final AppDatabase _db;

  /// Qurilma tartib raqami (chek raqami prefiksi `D3-`).
  final int deviceNumber;
  final IdGenerator _newId;
  final DateTime Function() _now;

  static const String _counter = 'sale';

  Future<RecordedSale> complete(CompletedSaleInput input) async {
    _validate(input);
    return _db.transaction(() async {
      final saleId = _newId();
      final eventId = _newId();
      final soldAt = _now();
      final number = await _nextNumber();

      final debtAmount = input.payments
          .where((p) => p.method == SalePaymentMethod.debt)
          .fold(0, (sum, p) => sum + p.amountTiyin);
      final debtEntryId = debtAmount > 0 ? _newId() : null;

      await _db
          .into(_db.sales)
          .insert(
            SalesCompanion.insert(
              id: saleId,
              shiftId: input.shiftId,
              cashierId: input.cashierId,
              customerId: Value(input.customerId),
              approvedBy: Value(input.approvedBy),
              number: number,
              subtotalTiyin: input.subtotalTiyin,
              discountTiyin: input.discountTiyin,
              totalTiyin: input.totalTiyin,
              debtEntryId: Value(debtEntryId),
              soldAt: soldAt,
            ),
          );

      final itemPayloads = <Map<String, Object?>>[];
      for (final (i, line) in input.lines.indexed) {
        final itemId = _newId();
        await _db
            .into(_db.saleItems)
            .insert(
              SaleItemsCompanion.insert(
                id: itemId,
                saleId: saleId,
                position: i,
                productId: line.productId,
                nameSnapshot: line.name,
                barcodeSnapshot: Value(line.barcode),
                qtyMilli: line.qtyMilli,
                priceTiyin: line.priceTiyin,
                costTiyin: line.costTiyin,
                discountTiyin: line.discountTiyin,
                totalTiyin: line.totalTiyin,
              ),
            );
        await _db
            .into(_db.stockMovements)
            .insert(
              StockMovementsCompanion.insert(
                id: _newId(),
                productId: line.productId,
                storeId: Value(input.storeId),
                qtyMilli: -line.qtyMilli,
                type: 'sale',
                refType: 'sale',
                refId: saleId,
                outboxEventId: Value(eventId),
                at: soldAt,
              ),
            );
        itemPayloads.add({
          'id': itemId,
          'product': line.productId,
          'name_snapshot': line.name,
          'barcode_snapshot': line.barcode ?? '',
          'qty_milli': line.qtyMilli,
          'price_tiyin': line.priceTiyin,
          'cost_tiyin': line.costTiyin,
          'discount_tiyin': line.discountTiyin,
          'total_tiyin': line.totalTiyin,
        });
      }

      final paymentPayloads = <Map<String, Object?>>[];
      for (final payment in input.payments) {
        final paymentId = _newId();
        await _db
            .into(_db.salePayments)
            .insert(
              SalePaymentsCompanion.insert(
                id: paymentId,
                saleId: saleId,
                method: payment.method.name,
                amountTiyin: payment.amountTiyin,
                receivedTiyin: Value(payment.receivedTiyin),
                changeTiyin: Value(payment.changeTiyin),
              ),
            );
        paymentPayloads.add({
          'id': paymentId,
          'method': payment.method.name,
          'amount_tiyin': payment.amountTiyin,
          'received_tiyin': ?payment.receivedTiyin,
          'change_tiyin': payment.changeTiyin,
        });
      }

      if (debtEntryId != null) {
        await _db
            .into(_db.debtEntries)
            .insert(
              DebtEntriesCompanion.insert(
                id: debtEntryId,
                customerId: input.customerId!,
                amountTiyin: debtAmount,
                type: 'sale',
                saleId: Value(saleId),
                shiftId: Value(input.shiftId),
                byUserId: Value(input.cashierId),
                at: soldAt,
              ),
            );
      }

      await _db.enqueueEvent(
        id: eventId,
        type: OutboxEventType.saleCompleted,
        createdAt: soldAt,
        payload: {
          'id': saleId,
          'shift': input.shiftId,
          'number': number,
          'cashier': input.cashierId,
          'customer': ?input.customerId,
          'approved_by': ?input.approvedBy,
          'sold_at': isoUtc(soldAt),
          'subtotal_tiyin': input.subtotalTiyin,
          'discount_tiyin': input.discountTiyin,
          'total_tiyin': input.totalTiyin,
          'debt_entry_id': ?debtEntryId,
          'items': itemPayloads,
          'payments': paymentPayloads,
        },
      );

      return RecordedSale(id: saleId, number: number);
    });
  }

  /// Keyingi chek raqami: `D3-000123`. Tranzaksiya ichida — bekor bo'lsa
  /// raqam ham qaytadi.
  Future<String> _nextNumber() async {
    final row = await (_db.select(
      _db.docCounters,
    )..where((t) => t.name.equals(_counter))).getSingleOrNull();
    final next = (row?.value ?? 0) + 1;
    await _db
        .into(_db.docCounters)
        .insertOnConflictUpdate(
          DocCountersCompanion.insert(name: _counter, value: next),
        );
    return 'D$deviceNumber-${next.toString().padLeft(6, '0')}';
  }

  static void _validate(CompletedSaleInput s) {
    Never fail(String reason) => throw InvalidSaleException(reason);

    if (s.lines.isEmpty) fail('no_items');
    for (final l in s.lines) {
      if (l.qtyMilli <= 0) fail('qty_not_positive');
      if (l.priceTiyin < 0 || l.costTiyin < 0 || l.discountTiyin < 0) {
        fail('negative_amount');
      }
      if (l.totalTiyin < 0) fail('line_discount_exceeds_total');
    }
    if (s.discountTiyin < 0 || s.discountTiyin > s.subtotalTiyin) {
      fail('discount_out_of_range');
    }
    if (s.payments.isEmpty) fail('no_payments');
    final paid = s.payments.fold(0, (sum, p) => sum + p.amountTiyin);
    if (paid != s.totalTiyin) fail('payments_do_not_match_total');
    for (final p in s.payments) {
      if (p.amountTiyin <= 0) fail('payment_not_positive');
      if (p.method == SalePaymentMethod.cash &&
          p.receivedTiyin! < p.amountTiyin) {
        fail('received_less_than_amount');
      }
      if (p.method == SalePaymentMethod.debt && s.customerId == null) {
        fail('debt_requires_customer');
      }
    }
  }
}

/// Joriy vaqt (testlarda flutter_test soxta vaqti).
DateTime _clockNow() => clock.now();
