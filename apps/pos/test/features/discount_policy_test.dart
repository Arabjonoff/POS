import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';

void main() {
  const cashier = DiscountPolicy(role: 'cashier');

  test('cashier gives up to 5% alone, more needs approval', () {
    expect(cashier.needsApproval(const Discount.percent(500), 100000), isFalse);
    expect(cashier.needsApproval(const Discount.percent(501), 100000), isTrue);
    // Summa ham foizga aylantirib tekshiriladi: 6 000 / 100 000 = 6%.
    expect(cashier.needsApproval(const Discount.amount(5000), 100000), isFalse);
    expect(cashier.needsApproval(const Discount.amount(6000), 100000), isTrue);
  });

  test('approved discount and manager/owner need nothing more', () {
    expect(
      cashier.needsApproval(
        const Discount.percent(5000, approvedBy: 'manager-1'),
        100000,
      ),
      isFalse,
    );
    for (final role in ['manager', 'owner']) {
      expect(
        DiscountPolicy(role: role).needsApproval(
          const Discount.percent(10000),
          100000,
        ),
        isFalse,
      );
    }
  });

  test('limit comes from the local setting', () {
    const strict = DiscountPolicy(role: 'cashier', cashierMaxBp: 0);
    expect(strict.needsApproval(const Discount.amount(1), 100000), isTrue);
  });

  test('approver is kept on the discount and the cart', () {
    final d = const Discount.amount(5000).approved('m1');
    expect(Discount.fromJson(d.toJson()), d);
    final cart = Cart(
      id: 'c',
      slot: 0,
      lines: [
        CartLine(
          id: 'l',
          productId: 'p',
          name: 'Non',
          unit: 'pcs',
          qtyMilli: 1000,
          priceTiyin: 100000,
          costTiyin: 0,
          discount: d,
        ),
      ],
    );
    expect(cart.approvedBy, 'm1');
  });
}
