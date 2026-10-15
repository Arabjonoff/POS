import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/money/money.dart';

void main() {
  test('matches server rounding vectors (testdata/money_rounding.json)', () {
    final data =
        jsonDecode(
              File('../../testdata/money_rounding.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final cases = (data['cases'] as List).cast<List<dynamic>>();
    expect(cases, isNotEmpty);
    for (final c in cases) {
      final [value, numerator, denominator, expected] = c.cast<int>();
      expect(
        Money.mulDivHalfUp(value, numerator, denominator),
        expected,
        reason: '$value × $numerator / $denominator',
      );
    }
  });

  test('line total and percent', () {
    expect(Money.lineTotal(600000, 1250), 750000);
    expect(Money.lineTotal(500000, 3000), 1500000);
    expect(Money.percentOf(1000000, 250), 25000);
  });

  test('VAT included in the price: total × 12 / 112, half up', () {
    // 44 500 so'm → 4 767,857… → 4 768 so'm (eskizdagi misol).
    expect(Money.vatIncluded(4450000), 476800);
    expect(Money.vatIncluded(1120000), 120000);
    expect(Money.vatIncluded(1000), 100);
    expect(Money.vatIncluded(0), 0);
  });

  test('no 64-bit overflow in the intermediate product', () {
    // 10 mlrd so'm × 1 mln dona.
    expect(
      Money.lineTotal(1000000000000, 1000000000),
      1000000000000000000,
    );
  });

  test('zero denominator is rejected', () {
    expect(() => Money.mulDivHalfUp(1, 1, 0), throwsArgumentError);
  });
}
