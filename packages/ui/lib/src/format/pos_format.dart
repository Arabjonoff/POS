/// Summa va miqdorni ekranga chiqarish (`docs/specs/i18n.md`).
///
/// Pul ichkarida butun son — tiyin (1 so'm = 100 tiyin), miqdor — `qty_milli`
/// (1 dona = 1000). Bu yerda `double` ishlatilmaydi. Valyuta nomi ("so'm",
/// "сўм", "сум") tarjima faylidan beriladi.
abstract final class PosFormat {
  /// Bo'linmaydigan bo'shliq — ming ajratuvchi va valyuta oldidan.
  static const String nbsp = ' ';

  /// Haqiqiy minus belgisi (defisdan ko'ra aniqroq o'qiladi).
  static const String minus = '−';

  /// Butun sonni minglarga ajratadi: `125000` → `125 000`.
  static String groupDigits(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? minus : '');
    final head = digits.length % 3;
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (i - head) % 3 == 0) buffer.write(nbsp);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Summa raqami valyutasiz: `12500000` → `125 000`; `12500050` → `125 000,50`.
  static String moneyAmount(int tiyin) {
    final abs = tiyin.abs();
    final som = groupDigits(abs ~/ 100);
    final rest = abs % 100;
    final sign = tiyin < 0 ? minus : '';
    if (rest == 0) return '$sign$som';
    return '$sign$som,${rest.toString().padLeft(2, '0')}';
  }

  /// To'liq summa: `125 000 so'm`.
  static String money(int tiyin, {required String currency}) =>
      '${moneyAmount(tiyin)}$nbsp$currency';

  /// Miqdor: dona — `3`, vazn — `1,250` (har doim 3 kasr xonasi).
  ///
  /// Dona tovarda kasr bo'lsa (masalan, `1500`), ortiqcha nollarsiz: `1,5`.
  static String qty(int qtyMilli, {bool weighted = false}) {
    final abs = qtyMilli.abs();
    final sign = qtyMilli < 0 ? minus : '';
    final whole = groupDigits(abs ~/ 1000);
    final rest = abs % 1000;
    if (weighted) return '$sign$whole,${rest.toString().padLeft(3, '0')}';
    if (rest == 0) return '$sign$whole';
    var fraction = rest.toString().padLeft(3, '0');
    while (fraction.endsWith('0')) {
      fraction = fraction.substring(0, fraction.length - 1);
    }
    return '$sign$whole,$fraction';
  }

  /// Miqdor birligi bilan: `1,250 kg`, `3 dona`.
  static String qtyWithUnit(
    int qtyMilli, {
    required String unit,
    bool weighted = false,
  }) => '${qty(qtyMilli, weighted: weighted)}$nbsp$unit';
}
