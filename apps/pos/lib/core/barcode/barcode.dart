/// Shtrix-kod qoidalari (`docs/specs/barcode.md`) — serverdagi
/// `apps/catalog/barcodes.py` bilan bir xil: kod — matn (boshidagi nollar
/// saqlanadi), 4–64 ko'rinadigan ASCII belgi, faqat raqamli 8/12/13 belgili
/// kodlarda (EAN-8, UPC-A, EAN-13) nazorat raqami tekshiriladi.
abstract final class Barcodes {
  static final RegExp _visibleAscii = RegExp(r'^[\x21-\x7e]{4,64}$');
  static final RegExp _digits = RegExp(r'^\d+$');
  static const Set<int> checkedLengths = {8, 12, 13};

  /// Bosh/oxirgi bo'shliqlarsiz kod yoki `null` (format noto'g'ri).
  static String? normalize(String raw) {
    final value = raw.trim();
    return _visibleAscii.hasMatch(value) ? value : null;
  }

  static BarcodeCheck check(String raw) {
    final value = normalize(raw);
    if (value == null) return BarcodeCheck.invalidFormat;
    if (_digits.hasMatch(value) && checkedLengths.contains(value.length)) {
      final body = value.substring(0, value.length - 1);
      if (gtinCheckDigit(body) != int.parse(value[value.length - 1])) {
        return BarcodeCheck.invalidCheckDigit;
      }
    }
    return BarcodeCheck.ok;
  }

  /// GTIN nazorat raqami: o'ngdan og'irliklar 3, 1, 3, 1, …
  static int gtinCheckDigit(String body) {
    var total = 0;
    for (var i = 0; i < body.length; i++) {
      final digit = body.codeUnitAt(body.length - 1 - i) - 0x30;
      total += digit * (i.isEven ? 3 : 1);
    }
    return (10 - total % 10) % 10;
  }
}

enum BarcodeCheck {
  ok,

  /// Bo'sh, juda qisqa/uzun yoki ko'rinmas belgilar.
  invalidFormat,

  /// EAN/UPC nazorat raqami mos emas — "Kod noto'g'ri o'qildi".
  invalidCheckDigit,
}

/// Tarozi shtrix-kodidagi qiymat: vazn yoki narx.
enum WeightedValueKind { weight, price }

/// Tarozi (vaznli) EAN-13 formati: `PP CCCCC WWWWW K` (sozlanadi).
class WeightedBarcodeFormat {
  const WeightedBarcodeFormat({
    this.prefixes = const {
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
      '26',
      '27',
      '28',
      '29',
    },
    this.pluLength = 5,
    this.valueKind = WeightedValueKind.weight,
    this.decimals = 3,
  }) : assert(pluLength >= 4 && pluLength <= 6, 'PLU 4–6 raqam');

  final Set<String> prefixes;
  final int pluLength;
  final WeightedValueKind valueKind;

  /// Qiymatdagi kasr xonalari: vazn uchun 3 — gramm (`01250` = 1,250 kg).
  final int decimals;

  /// Vaznli kod bo'lsa — PLU va miqdor/narx; aks holda `null`.
  WeightedBarcode? parse(String code) {
    if (code.length != 13 || !Barcodes._digits.hasMatch(code)) return null;
    if (Barcodes.check(code) != BarcodeCheck.ok) return null;
    final prefix = code.substring(0, 2);
    if (!prefixes.contains(prefix)) return null;
    final plu = code.substring(2, 2 + pluLength);
    final value = int.parse(code.substring(2 + pluLength, 12));
    return switch (valueKind) {
      // qty_milli: 1 kg = 1000.
      WeightedValueKind.weight => WeightedBarcode(
        code: code,
        plu: plu,
        qtyMilli: _scale(value, decimals, 3),
      ),
      // Narx so'mda → tiyin.
      WeightedValueKind.price => WeightedBarcode(
        code: code,
        plu: plu,
        priceTiyin: _scale(value, decimals, 2),
      ),
    };
  }

  /// `value / 10^from` ni `10^to` birlikka (butun sonlarda, kasrsiz).
  static int _scale(int value, int from, int to) {
    var result = value;
    for (var i = from; i < to; i++) {
      result *= 10;
    }
    for (var i = to; i < from; i++) {
      result ~/= 10;
    }
    return result;
  }
}

class WeightedBarcode {
  const WeightedBarcode({
    required this.code,
    required this.plu,
    this.qtyMilli,
    this.priceTiyin,
  });

  final String code;

  /// Tovarning `plu_code`.
  final String plu;

  /// Vazn (`weight` turida).
  final int? qtyMilli;

  /// Narx (`price` turida).
  final int? priceTiyin;
}
