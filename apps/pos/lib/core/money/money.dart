/// Pul va miqdor arifmetikasi — faqat butun sonlar (tiyin, `qty_milli`).
///
/// Serverdagi `apps/core/money.py` ning aniq nusxasi (qaror 0002): ikkalasi
/// ham `testdata/money_rounding.json` vektorlaridan o'tadi. Bo'lish va
/// yaxlitlash faqat shu yerda.
abstract final class Money {
  /// 1 dona = 1000 `qty_milli`.
  static const int qtyScale = 1000;

  /// `value * numerator / denominator`, yarim (.5) noldan uzoqqa yaxlitlanadi.
  ///
  /// Oraliq ko'paytma `BigInt` da — katta summa × katta miqdor 64 bitdan
  /// oshib ketmaydi.
  static int mulDivHalfUp(int value, int numerator, int denominator) {
    if (denominator == 0) {
      throw ArgumentError.value(denominator, 'denominator', 'must not be 0');
    }
    final product = BigInt.from(value) * BigInt.from(numerator);
    final negative = product.isNegative != denominator.isNegative;
    final d = BigInt.from(denominator).abs();
    final p = product.abs();
    var quotient = p ~/ d;
    final remainder = p.remainder(d);
    if (remainder * BigInt.two >= d) quotient += BigInt.one;
    final result = quotient.toInt();
    return negative ? -result : result;
  }

  /// Qator summasi: narx × miqdor (`qty_milli / 1000`).
  static int lineTotal(int priceTiyin, int qtyMilli) =>
      mulDivHalfUp(priceTiyin, qtyMilli, qtyScale);

  /// Summaning foizi; foiz bazis punktlarda (1% = 100).
  static int percentOf(int amountTiyin, int percentBp) =>
      mulDivHalfUp(amountTiyin, percentBp, 10000);
}
