import 'dart:convert';
import 'dart:typed_data';

import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/receipt.dart';

/// Printer kodlash jadvali (`printing.md`: CP866 yoki UTF-8).
enum PrinterEncoding {
  /// Ko'p termal printerlarda kirill — `ESC t n` (PC866, odatda n = 17).
  cp866('cp866'),
  utf8('utf8')
  ;

  const PrinterEncoding(this.code);

  final String code;

  static PrinterEncoding fromCode(String? code) =>
      values.firstWhere((e) => e.code == code, orElse: () => cp866);
}

/// Printer modeliga bog'liq sozlamalar (kassa sozlamasidan).
class EscPosProfile {
  const EscPosProfile({
    this.encoding = PrinterEncoding.cp866,
    this.codePage = EscPos.defaultCodePage,
    this.cancelKanji = true,
    this.cut = true,
    this.feedLines = 4,
  });

  final PrinterEncoding encoding;

  /// `ESC t n` dagi n (PC866 — ko'p printerlarda 17, ba'zilarida 7 yoki 59).
  final int codePage;

  /// Xitoy/Kanji rejimini o'chirish (`FS .`) — aks holda Xprinter kabi
  /// printerlarda kirill xitoycha belgilarga aylanadi.
  final bool cancelKanji;

  /// Kesuvchi pichoq bor (yo'q bo'lsa — faqat qog'oz suriladi).
  final bool cut;

  /// Kesishdan oldin qog'oz surish (qator).
  final int feedLines;
}

/// ESC/POS baytlari: chek qatorlari → printerga yuboriladigan buyruqlar.
/// Sof funksiya — printer yo'q (testlar baytlarni tekshiradi).
abstract final class EscPos {
  static const int defaultCodePage = 17;

  static const List<int> init = [0x1b, 0x40];
  static const List<int> alignLeft = [0x1b, 0x61, 0];
  static const List<int> alignCenter = [0x1b, 0x61, 1];
  static const List<int> boldOn = [0x1b, 0x45, 1];
  static const List<int> boldOff = [0x1b, 0x45, 0];

  /// `GS ! 0x01` — ikki barobar baland (kenglik o'zgarmaydi).
  static const List<int> tallOn = [0x1d, 0x21, 0x01];
  static const List<int> tallOff = [0x1d, 0x21, 0x00];

  /// `FS .` — Kanji (xitoy) rejimini o'chirish.
  static const List<int> cancelKanji = [0x1c, 0x2e];

  /// `ESC t 17` — PC866 (kirill).
  static const List<int> codePage866 = [0x1b, 0x74, defaultCodePage];

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

  /// Printer boshlanishi: `ESC @`, Kanji o'chirish, kodlash jadvali.
  static List<int> _start(EscPosProfile profile) => [
    ...init,
    if (profile.cancelKanji) ...cancelKanji,
    if (profile.encoding == PrinterEncoding.cp866) ...[
      0x1b,
      0x74,
      profile.codePage,
    ],
  ];

  /// Chek: boshlash, kodlash jadvali, qatorlar (markaz/qalin/baland),
  /// surish va kesish; [drawer] — boshida pul qutisini ochish.
  static Uint8List receipt(
    List<ReceiptRow> rows, {
    PrinterEncoding encoding = PrinterEncoding.cp866,
    EscPosProfile? profile,
    bool cut = true,
    bool drawer = false,
  }) {
    final p = profile ?? EscPosProfile(encoding: encoding, cut: cut);
    final out = BytesBuilder(copy: false)..add(_start(p));
    if (drawer) out.add(openDrawer);
    var center = false;
    var bold = false;
    var tall = false;
    for (final row in rows) {
      if (row.center != center) {
        center = row.center;
        out.add(center ? alignCenter : alignLeft);
      }
      if (row.bold != bold) {
        bold = row.bold;
        out.add(bold ? boldOn : boldOff);
      }
      if (row.tall != tall) {
        tall = row.tall;
        out.add(tall ? tallOn : tallOff);
      }
      final image = row.image;
      if (image != null) {
        out.add(raster(image));
        continue;
      }
      out
        ..add(row.barcode ? code128(row.text) : encode(row.text, p.encoding))
        ..addByte(_lf);
    }
    if (center) out.add(alignLeft);
    if (bold) out.add(boldOff);
    if (tall) out.add(tallOff);
    out.add([0x1b, 0x64, p.feedLines.clamp(0, 10)]);
    if (p.cut) out.add([0x1d, 0x56, 66, 0]);
    return out.takeBytes();
  }

  /// Rasm: `GS v 0` — 128 qatorli bo'laklarda (arzon printerlar buferi
  /// katta buyruqda to'lib qoladi).
  static List<int> raster(MonoBitmap image, {int band = 128}) {
    final out = <int>[];
    final w = image.bytesPerRow;
    for (var top = 0; top < image.height; top += band) {
      final rows = (image.height - top).clamp(0, band);
      out
        ..addAll([
          0x1d,
          0x76,
          0x30,
          0,
          w & 0xff,
          w >> 8,
          rows & 0xff,
          rows >> 8,
        ])
        ..addAll(image.bits.sublist(top * w, (top + rows) * w));
    }
    return out;
  }

  /// Faqat pul qutisini ochish (chek chiqarmasdan).
  static Uint8List drawerOnly() => Uint8List.fromList([...init, ...openDrawer]);

  static List<int> encode(String text, PrinterEncoding encoding) =>
      switch (encoding) {
        PrinterEncoding.utf8 => utf8.encode(text),
        PrinterEncoding.cp866 => [for (final r in text.runes) _cp866(r)],
      };

  /// Printer qog'ozda nima chiqaradi (chek ko'rinishi uchun): CP866 da
  /// yo'q harflar eng yaqiniga, umuman yo'qlari — `?`.
  static String printable(String text, PrinterEncoding encoding) {
    if (encoding == PrinterEncoding.utf8) return text;
    final out = StringBuffer();
    for (final rune in text.runes) {
      final folded = _uzbek[rune] ?? rune;
      out.write(
        _cp866(rune) == 0x3f && rune != 0x3f
            ? '?'
            : String.fromCharCode(folded),
      );
    }
    return out.toString();
  }

  /// O'zbek kirill harflaridan CP866 da yo'qlari — eng yaqiniga
  /// (Ў/ў jadvalda bor: 0xF6/0xF7).
  static const Map<int, int> _uzbek = {
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
      0x040e => 0xf6, // Ў
      0x045e => 0xf7, // ў
      0x00b0 => 0xf8, // °
      0x2116 => 0xfc, // №
      _ => 0x3f, // ?
    };
  }
}
