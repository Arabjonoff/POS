import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';

const int total = 12530000; // 125 300 so'm

(SalePaymentMethod, int, int?) row(SalePaymentInput p) =>
    (p.method, p.amountTiyin, p.receivedTiyin);

void main() {
  group('cash', () {
    test('exact by default: no change', () {
      const d = PaymentDraft(totalTiyin: total);
      expect(d.isValid, isTrue);
      expect(d.changeTiyin, 0);
      expect(d.toPayments().map(row), [
        (SalePaymentMethod.cash, total, total),
      ]);
    });

    test('received more → change; less → not enough', () {
      final d = const PaymentDraft(
        totalTiyin: total,
      ).copyWith(receivedTiyin: 20000000);
      expect(d.changeTiyin, 7470000);
      expect(d.toPayments().single.changeTiyin, 7470000);

      final short = d.copyWith(receivedTiyin: 10000000);
      expect(short.problem, PaymentProblem.notEnoughCash);
      expect(short.isValid, isFalse);
      expect(short.copyWith(exact: true).isValid, isTrue);
    });
  });

  test('card and debt take the whole total', () {
    const card = PaymentDraft(totalTiyin: total, mode: PayMode.card);
    expect(card.toPayments().map(row), [
      (SalePaymentMethod.card, total, null),
    ]);
    const debt = PaymentDraft(totalTiyin: total, mode: PayMode.debt);
    expect(debt.problem, PaymentProblem.customerRequired);
    final withCustomer = debt.copyWith(customerId: 'c1');
    expect(withCustomer.isValid, isTrue);
    expect(withCustomer.toPayments().map(row), [
      (SalePaymentMethod.debt, total, null),
    ]);
  });

  group('mixed', () {
    test('card + debt + rest in cash with change', () {
      final d =
          const PaymentDraft(
            totalTiyin: total,
            mode: PayMode.mixed,
            customerId: 'c1',
          ).copyWith(
            cardTiyin: 5000000,
            debtTiyin: 3000000,
            receivedTiyin: 5000000,
          );
      expect(d.cashDue, 4530000);
      expect(d.changeTiyin, 470000);
      expect(d.toPayments().map(row), [
        (SalePaymentMethod.cash, 4530000, 5000000),
        (SalePaymentMethod.card, 5000000, null),
        (SalePaymentMethod.debt, 3000000, null),
      ]);
      final sum = d.toPayments().fold(0, (s, p) => s + p.amountTiyin);
      expect(sum, total);
    });

    test('card covers everything → no cash line', () {
      const d = PaymentDraft(
        totalTiyin: total,
        mode: PayMode.mixed,
        cardTiyin: total,
      );
      expect(d.isValid, isTrue);
      expect(d.toPayments().map(row), [(SalePaymentMethod.card, total, null)]);
    });

    test('parts above the total are rejected', () {
      const d = PaymentDraft(
        totalTiyin: total,
        mode: PayMode.mixed,
        cardTiyin: total,
        debtTiyin: 1,
        customerId: 'c1',
      );
      expect(d.problem, PaymentProblem.partsExceedTotal);
    });

    test('debt part needs a customer', () {
      const d = PaymentDraft(
        totalTiyin: total,
        mode: PayMode.mixed,
        debtTiyin: 100,
      );
      expect(d.problem, PaymentProblem.customerRequired);
    });
  });
}
