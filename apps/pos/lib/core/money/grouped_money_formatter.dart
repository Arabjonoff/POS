import 'package:flutter/services.dart';

/// Butun so'm kiritish: faqat raqamlar, mingliklar bo'shliq bilan
/// (`1500000` → `1 500 000`) — katta summani ko'z bilan tekshirish oson.
/// [maxDigits] — so'mdagi raqamlar chegarasi.
class GroupedMoneyFormatter extends TextInputFormatter {
  const GroupedMoneyFormatter({this.maxDigits = 12});

  final int maxDigits;

  /// Matndan tiyin (`null` — bo'sh).
  static int? parseTiyin(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.parse(digits) * 100;
  }

  static String format(String digits) {
    final clean = digits.replaceFirst(RegExp('^0+(?=.)'), '');
    final out = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) out.write(' ');
      out.write(clean[i]);
    }
    return out.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) return oldValue;
    final text = format(digits);
    // Kursor oxirida (summa odatda oxiridan yoziladi).
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
