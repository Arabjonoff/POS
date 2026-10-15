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

/// So'm (2 kasr xonagacha) kiritish: `1500000,5` → `1 500 000,5`. Nuqta
/// vergulga aylanadi; harflar tushadi. Kursor raqamlar bo'yicha saqlanadi —
/// summani o'rtasidan tahrirlash ham ishlaydi. O'qish: `parseMoneyTiyin`.
class DecimalMoneyFormatter extends TextInputFormatter {
  const DecimalMoneyFormatter({this.maxDigits = 12});

  final int maxDigits;

  static final _nonDigit = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll('.', ',');
    final comma = raw.indexOf(',');
    final whole = (comma < 0 ? raw : raw.substring(0, comma)).replaceAll(
      _nonDigit,
      '',
    );
    final frac = comma < 0
        ? null
        : raw.substring(comma + 1).replaceAll(_nonDigit, '');
    if (whole.length > maxDigits || (frac?.length ?? 0) > 2) return oldValue;
    final grouped = whole.isEmpty && frac != null
        ? '0'
        : GroupedMoneyFormatter.format(whole);
    final text = frac == null ? grouped : '$grouped,$frac';

    // Kursorgacha bo'lgan raqam va vergullar soni — yangi matnda o'sha joy.
    final cursor = newValue.selection.baseOffset.clamp(0, raw.length);
    var marks = 0;
    for (var i = 0; i < cursor; i++) {
      if ('0123456789,'.contains(raw[i])) marks++;
    }
    var offset = 0;
    for (var seen = 0; offset < text.length && seen < marks; offset++) {
      if (text[offset] != ' ') seen++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
