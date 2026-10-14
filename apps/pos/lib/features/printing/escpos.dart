import 'dart:convert';
import 'dart:typed_data';

import 'package:pos_app/features/printing/receipt.dart';

/// Printer kodlash jadvali (`printing.md`: CP866 yoki UTF-8).
enum PrinterEncoding {
  /// Ko'p termal printerlarda kirill — `ESC t 17` (PC866).
  cp866('cp866'),
  utf8('utf8')
  ;

  const PrinterEncoding(this.code);

  final String code;

  static PrinterEncoding fromCode(String? code) =>
      values.firstWhere((e) => e.code == code, orElse: () => cp866);
}

/// ESC/POS baytlari: chek qatorlari → printerga yuboriladigan buyruqlar.
/// Sof funksiya — printer yo'q (testlar baytlarni tekshiradi).
abstract final class EscPos {
  static const List<int> init = [0x1b, 0x40];
  static const List<int> alignLeft = [0x1b, 0x61, 0];
  static const List<int> alignCenter = [0x1b, 0x61, 1];
  static const List<int> boldOn = [0x1b, 0x45, 1];
  static const List<int> boldOff = [0x1b, 0x45, 0];

  /// `ESC t 17` — PC866 (kirill).
  static const List<int> codePage866 = [0x1b, 0x74, 17];

  /// Qog'ozni 4 qator surib, qisman kesish (`GS V 66 0`).
  static const List<int> feedAndCut = [0x1b, 0x64, 4, 0x1d, 0x56, 66, 0];

  /// Pul qutisi: 2-pin, 50 ms yoqish / 500 ms o'chirish (`ESC p 0 25 250`).
  static const List<int> openDrawer = [0x1b, 0x70, 0, 25, 250];

  static const int _lf = 0x0a;

  /// CODE128 (B to'plami): balandlik 60 nuqta, kenglik 2, raqam ostida.
  static List<int> code128(String data) {
    final bytes = ascii.encode(data);
    return [
      0x1d, 0x68, 60, // GS h — balandlik
      0x1d, 0x77, 2, // GS w — chiziq kengligi
      0x1d, 0x48, 2, // GS H — matn ostida
      0x1d, 0x6b, 73, bytes.length + 2, 0x7b, 0x42, // GS k 73 n {B
      ...bytes,
    ];
  }

  /// Chek: boshlash, kodlash jadvali, qatorlar (markaz/qalin), kesish;
  /// [drawer] — boshida pul qutisini ochish.
  static Uint8List receipt(
    List<ReceiptRow> rows, {
    PrinterEncoding encoding = PrinterEncoding.cp866,
    bool cut = true,
    bool drawer = false,
  }) {
    final out = BytesBuilder(copy: false)..add(init);
    if (encoding == PrinterEncoding.cp866) out.add(codePage866);
    if (drawer) out.add(openDrawer);
    var center = false;
    var bold = false;
    for (final row in rows) {
      if (row.center != center) {
        center = row.center;
        out.add(center ? alignCenter : alignLeft);
      }
      if (row.bold != bold) {
        bold = row.bold;
        out.add(bold ? boldOn : boldOff);
      }
      out
        ..add(row.barcode ? code128(row.text) : encode(row.text, encoding))
        ..addByte(_lf);
    }
    if (center) out.add(alignLeft);
    if (bold) out.add(boldOff);
    if (cut) out.add(feedAndCut);
    return out.takeBytes();
  }

  /// Faqat pul qutisini ochish (chek chiqarmasdan).
  static Uint8List drawerOnly() => Uint8List.fromList([...init, ...openDrawer]);

  static List<int> encode(String text, PrinterEncoding encoding) =>
      switch (encoding) {
        PrinterEncoding.utf8 => utf8.encode(text),
        PrinterEncoding.cp866 => [for (final r in text.runes) _cp866(r)],
      };

  /// O'zbek kirill harflari CP866 da yo'q — eng yaqiniga.
  static const Map<int, int> _uzbek = {
    0x040e: 0x0423, // Ў → У
    0x045e: 0x0443, // ў → у
    0x049a: 0x041a, // Қ → К
    0x049b: 0x043a, // қ → к
    0x0492: 0x0413, // Ғ → Г
    0x0493: 0x0433, // ғ → г
    0x04b2: 0x0425, // Ҳ → Х
    0x04b3: 0x0445, // ҳ → х
  };

  static int _cp866(int rune) {
    final r = _uzbek[rune] ?? rune;
    if (r < 0x80) return r;
    if (r >= 0x0410 && r <= 0x043f) return r - 0x0410 + 0x80; // А-п
    if (r >= 0x0440 && r <= 0x044f) return r - 0x0440 + 0xe0; // р-я
    return switch (r) {
      0x0401 => 0xf0, // Ё
      0x0451 => 0xf1, // ё
      0x2116 => 0xfc, // №
      _ => 0x3f, // ?
    };
  }
}
