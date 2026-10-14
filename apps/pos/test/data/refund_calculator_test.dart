import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/refunds/refund_calculator.dart';

/// Vektorlar — `backend/apps/sales/tests/test_refunds.py` bilan bir xil.
RefundableSale sale({
  required List<RefundableItem> items,
  int discount = 0,
  int refunded = 0,
  int debtPaid = 0,
  int debtRefunded = 0,
}) {
  final subtotal = items.fold(0, (s, i) => s + i.totalTiyin);
  return RefundableSale(
    id: 's1',
    number: 'D3-000001',
    soldAt: DateTime.utc(2026, 10, 15),
    subtotalTiyin: subtotal,
    discountTiyin: discount,
    totalTiyin: subtotal - discount,
    items: items,
    refundedTiyin: refunded,
    debtPaidTiyin: debtPaid,
    debtRefundedTiyin: debtRefunded,
  );
}

RefundableItem item(
  String id,
  int qty,
  int price, {
  int refundedQty = 0,
  int refundedTiyin = 0,
}) => RefundableItem(
  saleItemId: id,
  productId: 'p-$id',
  name: id,
  unit: 'pcs',
  qtyMilli: qty,
  priceTiyin: price,
  totalTiyin: price * qty ~/ 1000,
  refundedQtyMilli: refundedQty,
  refundedTiyin: refundedTiyin,
);

void main() {
  test('partial then full refund of one line', () {
    final first = RefundQuote.of(
      sale(items: [item('a', 3000, 400000)]),
      {'a': 1000},
    );
    expect(first.totalTiyin, 400000);
    expect(first.closesSale, isFalse);

    final rest = RefundQuote.of(
      sale(
        items: [
          item('a', 3000, 400000, refundedQty: 1000, refundedTiyin: 400000),
        ],
        refunded: 400000,
      ),
      {'a': 2000},
    );
    expect(rest.lines.single.totalTiyin, 800000);
    expect(rest.totalTiyin, 800000);
    expect(rest.closesSale, isTrue);
  });

  test('rounding remainder is closed on the last part', () {
    // 3 × 333 tiyin, chek chegirmasi 100: jami 899.
    final items = [item('a', 3000, 333)];
    var refundedQty = 0;
    var refundedLine = 0;
    var refunded = 0;
    for (var i = 0; i < 3; i++) {
      final quote = RefundQuote.of(
        sale(
          items: [
            item(
              'a',
              3000,
              333,
              refundedQty: refundedQty,
              refundedTiyin: refundedLine,
            ),
          ],
          discount: 100,
          refunded: refunded,
        ),
        {'a': 1000},
      );
      refundedQty += 1000;
      refundedLine += quote.lines.single.totalTiyin;
      refunded += quote.totalTiyin;
    }
    expect(refundedLine, items.single.totalTiyin);
    expect(refunded, 899);
  });

  test('check discount share on a partial refund', () {
    final quote = RefundQuote.of(
      sale(
        items: [item('bread', 1000, 600000), item('milk', 1000, 400000)],
        discount: 100000,
      ),
      {'bread': 1000},
    );
    // 600 000 − 100 000 × 600 000 / 1 000 000.
    expect(quote.totalTiyin, 540000);
    expect(quote.closesSale, isFalse);
  });

  test('weighted: part of the weight', () {
    // 1,250 kg × 15 000 = 18 750; 0,500 kg → 7 500.
    final s = sale(items: [item('olma', 1250, 1500000)]);
    expect(RefundQuote.of(s, {'olma': 500}).totalTiyin, 750000);
  });

  test('debt: only up to the debt part that is left', () {
    final s = sale(
      items: [item('a', 2000, 400000)],
      debtPaid: 200000,
    );
    final one = RefundQuote.of(s, {'a': 1000});
    expect(one.debtAllowed(s), isFalse);
    final cashOnly = sale(items: [item('a', 2000, 400000)]);
    expect(
      RefundQuote.of(cashOnly, {'a': 1000}).debtAllowed(cashOnly),
      isFalse,
    );
    final debt = sale(items: [item('a', 2000, 400000)], debtPaid: 800000);
    expect(RefundQuote.of(debt, {'a': 1000}).debtAllowed(debt), isTrue);
  });

  test('invalid: nothing chosen, too much, unknown line', () {
    final s = sale(items: [item('a', 2000, 400000, refundedQty: 1000)]);
    expect(
      () => RefundQuote.of(s, {'a': 0}),
      throwsA(
        isA<InvalidRefundException>().having(
          (e) => e.problem,
          'problem',
          RefundProblem.empty,
        ),
      ),
    );
    expect(
      () => RefundQuote.of(s, {'a': 1001}),
      throwsA(
        isA<InvalidRefundException>().having(
          (e) => e.problem,
          'problem',
          RefundProblem.qtyExceedsRemaining,
        ),
      ),
    );
    expect(
      () => RefundQuote.of(s, {'x': 1000}),
      throwsA(isA<InvalidRefundException>()),
    );
  });
}
