import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_sample.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

/// 16 × 4: chap yarmi qora, o'ng yarmi oq.
GrayImage halves() => GrayImage(
  16,
  4,
  Uint8List.fromList([
    for (var y = 0; y < 4; y++)
      for (var x = 0; x < 16; x++) x < 8 ? 0 : 255,
  ]),
);

void main() {
  final l10n = lookupAppLocalizations(AppLocales.uzLatn);

  test('gray PNG round-trips (server stores it, kassa reads it back)', () {
    final image = halves();
    final png = image.toPng();
    expect(png.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final back = GrayImage.fromPng(png)!;
    expect((back.width, back.height), (16, 4));
    expect(back.pixels, image.pixels);
    expect(GrayImage.fromPng(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('transparent pixels become white paper', () {
    final rgba = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 255]);
    expect(GrayImage.fromRgba(2, 1, rgba).pixels, [255, 0]);
  });

  test('fit keeps the aspect ratio and never upscales', () {
    final big = GrayImage(1200, 600, Uint8List(1200 * 600));
    final fitted = big.fit(576, 240);
    expect((fitted.width, fitted.height), (480, 240));
    expect(identical(halves().fit(576, 240).pixels, halves().pixels), isFalse);
    expect(halves().fit(576, 240).width, 16);
  });

  test('1-bit bitmap: MSB first, black below the threshold', () {
    final bmp = MonoBitmap.fromGray(halves(), maxDots: 384);
    expect((bmp.width, bmp.height, bmp.bytesPerRow), (16, 4, 2));
    expect(bmp.bits.sublist(0, 2), [0xff, 0x00]);
    expect(bmp.isBlack(0, 0), isTrue);
    expect(bmp.isBlack(15, 3), isFalse);
  });

  test('raster: GS v 0 in bands of ≤ 128 rows', () {
    final tall = MonoBitmap(8, 300, Uint8List(300));
    final bytes = EscPos.raster(tall);
    final headers = <int>[];
    for (var i = 0; i + 3 < bytes.length; i++) {
      if (bytes[i] == 0x1d && bytes[i + 1] == 0x76 && bytes[i + 2] == 0x30) {
        headers.add(bytes[i + 6] | bytes[i + 7] << 8);
      }
    }
    expect(headers, [128, 128, 44]);
    expect(bytes.length, 3 * 8 + 300);
  });

  test('logo and requisites on the receipt; hidden fields are not printed', () {
    final logo = halves();
    final base = sampleReceipt(
      l10n,
      storeName: 'Baraka',
      at: DateTime.utc(2026),
    );
    ReceiptData data(ReceiptOptions options, {String tin = '123456789'}) =>
        base.withStore(
          storeName: 'Baraka',
          storeAddress: 'Chilonzor 7',
          storePhone: '+998712000000',
          header: '',
          footer: '',
          legalName: '"Baraka" MChJ',
          tin: tin,
          logo: logo,
          options: options,
        );
    var rows = ReceiptBuilder(l10n).build(data(const ReceiptOptions()));
    expect(rows.first.image, isNotNull);
    final text = [for (final r in rows) r.text.trim()];
    expect(text, contains('"Baraka" MChJ'));
    expect(text, contains('STIR: 123456789'));
    // 14 raqam — JShShIR.
    rows = ReceiptBuilder(
      l10n,
    ).build(data(const ReceiptOptions(), tin: '12345678901234'));
    expect([
      for (final r in rows) r.text.trim(),
    ], contains('JShShIR: 12345678901234'));

    // Yashirilganlar chiqmaydi; soliq raqami bo'sh bo'lsa — umuman yo'q.
    rows = ReceiptBuilder(l10n).build(
      data(
        const ReceiptOptions(
          showLogo: false,
          showLegalName: false,
          showTin: false,
          showCashier: false,
          showBarcode: false,
        ),
      ),
    );
    expect(rows.any((r) => r.image != null || r.barcode), isFalse);
    final hidden = rows.map((r) => r.text).join('\n');
    expect(hidden, isNot(contains('MChJ')));
    expect(hidden, isNot(contains('STIR')));
    expect(hidden, isNot(contains('Kassir')));
    rows = ReceiptBuilder(l10n).build(data(const ReceiptOptions(), tin: ''));
    expect(rows.map((r) => r.text).join('\n'), isNot(contains('STIR')));
  });

  test('the logo is printed as raster, within the paper width', () {
    final wide = GrayImage(1000, 100, Uint8List(1000 * 100));
    final rows = ReceiptBuilder(l10n, width: PaperWidth.mm58).build(
      sampleReceipt(l10n, at: DateTime.utc(2026)).withStore(
        storeName: 'X',
        storeAddress: '',
        storePhone: '',
        header: '',
        footer: '',
        legalName: '',
        tin: '',
        logo: wide,
        options: const ReceiptOptions(),
      ),
    );
    expect(rows.first.image!.width, 384);
    final bytes = EscPos.receipt(rows);
    expect(String.fromCharCodes(bytes).contains('\x1dv0'), isTrue);
  });

  test('options JSON: unknown keys ignored, missing keys default to shown', () {
    final o = ReceiptOptions.fromJson({
      'show_tin': false,
      'x': 1,
      'show_logo': 'no',
    });
    expect((o.showTin, o.showLogo, o.showCashier), (false, true, true));
    expect(ReceiptOptions.fromJson(o.toJson()).showTin, isFalse);
  });
}
