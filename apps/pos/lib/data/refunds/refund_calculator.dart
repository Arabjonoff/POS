import 'package:pos_app/core/money/money.dart';

/// Qaytarish mumkin bo'lgan savdo qatori: sotilgan va oldin qaytarilgan.
class RefundableItem {
  const RefundableItem({
    required this.saleItemId,
    required this.productId,
    required this.name,
    required this.unit,
    required this.qtyMilli,
    required this.priceTiyin,
    required this.totalTiyin,
    this.refundedQtyMilli = 0,
    this.refundedTiyin = 0,
  });

  final String saleItemId;
  final String productId;
  final String name;

  /// Birlik kodi (`pcs`, `kg`, ...).
  final String unit;
  final int qtyMilli;
  final int priceTiyin;

  /// Qator jami (qator chegirmasidan keyin).
  final int totalTiyin;
  final int refundedQtyMilli;
  final int refundedTiyin;

  int get remainingQtyMilli => qtyMilli - refundedQtyMilli;
}

/// Qaytarish uchun savdo: qatorlar, chegirma, oldingi qaytarishlar, nasiya.
class RefundableSale {
  const RefundableSale({
    required this.id,
    required this.number,
    required this.soldAt,
    required this.subtotalTiyin,
    required this.discountTiyin,
    required this.totalTiyin,
    required this.items,
    this.customerId,
    this.refundedTiyin = 0,
    this.debtPaidTiyin = 0,
    this.debtRefundedTiyin = 0,
  });

  final String id;
  final String number;
  final DateTime soldAt;
  final String? customerId;
  final int subtotalTiyin;

  /// Butun chekka chegirma.
  final int discountTiyin;
  final int totalTiyin;
  final List<RefundableItem> items;

  /// Oldingi qaytarishlar jami.
  final int refundedTiyin;
  final int debtPaidTiyin;
  final int debtRefundedTiyin;

  /// Qarzdan ayirish mumkin bo'lgan qoldiq.
  int get debtLeftTiyin => debtPaidTiyin - debtRefundedTiyin;

  bool get fullyRefunded => items.every((i) => i.remainingQtyMilli <= 0);
}

class RefundLine {
  const RefundLine({
    required this.saleItemId,
    required this.qtyMilli,
    required this.totalTiyin,
  });

  final String saleItemId;
  final int qtyMilli;
  final int totalTiyin;
}

enum RefundProblem {
  /// Hech narsa tanlanmagan.
  empty,

  /// Miqdor qolgandan ko'p (yoki manfiy).
  qtyExceedsRemaining,

  /// Bunday qator savdoda yo'q.
  unknownItem,
}

class InvalidRefundException implements Exception {
  const InvalidRefundException(this.problem);

  final RefundProblem problem;

  @override
  String toString() => 'InvalidRefundException(${problem.name})';
}

/// Qaytariladigan summa. Server `record_refund` bilan **aynan bir xil**
/// (`docs/specs/sales-api.md`), aks holda hodisa rad etiladi:
/// - qator: `mulDivHalfUp(qator jami, qty, sotilgan)`; qatorning oxirgi
///   qismi — `qator jami − oldin qaytarilgan` (yaxlitlash qoldig'i yopiladi);
/// - jami: `Σ qator − chek chegirmasidan ulush`; savdo to'liq yopilsa —
///   `savdo jami − oldingi qaytarishlar`.
class RefundQuote {
  RefundQuote._(this.lines, this.totalTiyin, {required this.closesSale});

  /// [qtyBySaleItem] — qaytariladigan miqdorlar (`0` — qaytarilmaydi).
  factory RefundQuote.of(RefundableSale sale, Map<String, int> qtyBySaleItem) {
    final byId = {for (final i in sale.items) i.saleItemId: i};
    final lines = <RefundLine>[];
    final remaining = {
      for (final i in sale.items) i.saleItemId: i.remainingQtyMilli,
    };
    for (final MapEntry(key: id, value: qty) in qtyBySaleItem.entries) {
      if (qty == 0) continue;
      final item = byId[id];
      if (item == null) {
        throw const InvalidRefundException(RefundProblem.unknownItem);
      }
      if (qty < 0 || qty > item.remainingQtyMilli) {
        throw const InvalidRefundException(RefundProblem.qtyExceedsRemaining);
      }
      final total = qty == item.remainingQtyMilli
          ? item.totalTiyin - item.refundedTiyin
          : Money.mulDivHalfUp(item.totalTiyin, qty, item.qtyMilli);
      lines.add(RefundLine(saleItemId: id, qtyMilli: qty, totalTiyin: total));
      remaining[id] = remaining[id]! - qty;
    }
    if (lines.isEmpty) throw const InvalidRefundException(RefundProblem.empty);

    final closes = remaining.values.every((q) => q == 0);
    final itemsSum = lines.fold(0, (sum, l) => sum + l.totalTiyin);
    final total = closes
        ? sale.totalTiyin - sale.refundedTiyin
        : sale.subtotalTiyin == 0
        ? itemsSum
        : itemsSum -
              Money.mulDivHalfUp(
                sale.discountTiyin,
                itemsSum,
                sale.subtotalTiyin,
              );
    return RefundQuote._(lines, total, closesSale: closes);
  }

  final List<RefundLine> lines;
  final int totalTiyin;

  /// Savdo to'liq qaytarildi (`status = refunded`).
  final bool closesSale;

  /// Qarzdan ayirish mumkinmi (savdoda nasiya qismi yetarli).
  bool debtAllowed(RefundableSale sale) =>
      sale.debtLeftTiyin > 0 && totalTiyin <= sale.debtLeftTiyin;
}
