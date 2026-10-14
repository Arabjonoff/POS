import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/receipt.dart';

void main() {
  test('CP866: latin as is, russian and uzbek cyrillic', () {
    expect(
      EscPos.encode("Non so'm", PrinterEncoding.cp866),
      ascii.encode("Non so'm"),
    );
    // А Я а п р я Ё ё
    expect(EscPos.encode('АЯапряЁё', PrinterEncoding.cp866), [
      0x80,
      0x9f,
      0xa0,
      0xaf,
      0xe0,
      0xef,
      0xf0,
      0xf1,
    ]);
    // Ўзбек → Узбек; қ ғ ҳ → к г х.
    expect(
      EscPos.encode('Ўқғҳ', PrinterEncoding.cp866),
      EscPos.encode('Укгх', PrinterEncoding.cp866),
    );
    expect(EscPos.encode('€', PrinterEncoding.cp866), [0x3f]);
  });

  test('UTF-8 passes text through', () {
    expect(EscPos.encode('Жами', PrinterEncoding.utf8), utf8.encode('Жами'));
  });

  test('receipt: init, code page, alignment, bold, cut', () {
    final bytes = EscPos.receipt(const [
      ReceiptRow("Do'kon", bold: true, center: true),
      ReceiptRow('JAMI  1'),
    ]);
    expect(bytes, [
      ...EscPos.init,
      ...EscPos.codePage866,
      ...EscPos.alignCenter,
      ...EscPos.boldOn,
      ...ascii.encode("Do'kon"),
      0x0a,
      ...EscPos.alignLeft,
      ...EscPos.boldOff,
      ...ascii.encode('JAMI  1'),
      0x0a,
      ...EscPos.feedAndCut,
    ]);
  });

  test('drawer pulse comes first; UTF-8 has no code page command', () {
    final bytes = EscPos.receipt(
      const [ReceiptRow('x')],
      encoding: PrinterEncoding.utf8,
      drawer: true,
      cut: false,
    );
    expect(bytes, [...EscPos.init, ...EscPos.openDrawer, 0x78, 0x0a]);
    expect(EscPos.drawerOnly(), [...EscPos.init, ...EscPos.openDrawer]);
  });

  test('encoding codes round-trip; unknown → CP866', () {
    for (final e in PrinterEncoding.values) {
      expect(PrinterEncoding.fromCode(e.code), e);
    }
    expect(PrinterEncoding.fromCode(null), PrinterEncoding.cp866);
  });

  test('sale number barcode: CODE128 set B, centered', () {
    final bytes = EscPos.receipt(const [
      ReceiptRow.barcode('D3-000123'),
    ], cut: false);
    expect(bytes, [
      ...EscPos.init,
      ...EscPos.codePage866,
      ...EscPos.alignCenter,
      0x1d,
      0x68,
      60,
      0x1d,
      0x77,
      2,
      0x1d,
      0x48,
      2,
      0x1d,
      0x6b,
      73,
      11,
      0x7b,
      0x42,
      ...ascii.encode('D3-000123'),
      0x0a,
      ...EscPos.alignLeft,
    ]);
  });
}
