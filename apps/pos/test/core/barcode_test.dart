import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/barcode/barcode.dart';

void main() {
  group('Barcodes.check', () {
    test('valid EAN-13, EAN-8, UPC-A', () {
      for (final code in [
        '4780001000013', // EAN-13
        '4006381333931', // EAN-13
        '96385074', // EAN-8
        '036000291452', // UPC-A
        '2012345012509', // tarozi EAN-13
      ]) {
        expect(Barcodes.check(code), BarcodeCheck.ok, reason: code);
      }
    });

    test('wrong check digit is rejected', () {
      for (final code in [
        '4780001000012',
        '4006381333932',
        '96385075',
        '036000291453',
        '2012345012503', // barcode.md eski xatosi (T-014)
      ]) {
        expect(
          Barcodes.check(code),
          BarcodeCheck.invalidCheckDigit,
          reason: code,
        );
      }
    });

    test('other lengths and alphanumeric codes are not checksummed', () {
      expect(Barcodes.check('12345'), BarcodeCheck.ok);
      expect(Barcodes.check('ABC-123'), BarcodeCheck.ok);
      expect(Barcodes.check('12345678901234'), BarcodeCheck.ok);
    });

    test('format: trimmed, 4–64 visible ASCII, leading zeros kept', () {
      expect(Barcodes.normalize('  0012345678905 '), '0012345678905');
      expect(Barcodes.check('123'), BarcodeCheck.invalidFormat);
      expect(Barcodes.check('12 34'), BarcodeCheck.invalidFormat);
      expect(Barcodes.check('Ўзб1'), BarcodeCheck.invalidFormat);
      expect(Barcodes.check('x' * 65), BarcodeCheck.invalidFormat);
      expect(Barcodes.check(''), BarcodeCheck.invalidFormat);
    });

    test('check digit algorithm', () {
      expect(Barcodes.gtinCheckDigit('478000100001'), 3);
      expect(Barcodes.gtinCheckDigit('9638507'), 4);
      expect(Barcodes.gtinCheckDigit('03600029145'), 2);
    });
  });

  group('WeightedBarcodeFormat', () {
    const format = WeightedBarcodeFormat();

    test('barcode.md example: 2012345012509 → PLU 12345, 1,250 kg', () {
      final parsed = format.parse('2012345012509')!;
      expect(parsed.plu, '12345');
      expect(parsed.qtyMilli, 1250);
      expect(parsed.priceTiyin, isNull);
    });

    test('ordinary EAN-13 and wrong check digits are not weighted', () {
      expect(format.parse('4780001000013'), isNull);
      expect(format.parse('2012345012503'), isNull);
      expect(format.parse('201234501250'), isNull);
    });

    test('prefix range is configurable', () {
      const only22 = WeightedBarcodeFormat(prefixes: {'22'});
      expect(only22.parse('2012345012509'), isNull);
    });

    test('price kind and decimals', () {
      // 21 00077 15000 K: narx 15 000 so'm.
      const body = '210007715000';
      final code = '$body${Barcodes.gtinCheckDigit(body)}';
      const priced = WeightedBarcodeFormat(
        valueKind: WeightedValueKind.price,
        decimals: 0,
      );
      final parsed = priced.parse(code)!;
      expect(parsed.plu, '00077');
      expect(parsed.priceTiyin, 1500000);

      // Vazn 2 kasr bilan (10 g birlik): 00125 → 1,25 kg = 1250 milli.
      const grams10 = WeightedBarcodeFormat(decimals: 2);
      const b2 = '200007700125';
      expect(
        grams10.parse('$b2${Barcodes.gtinCheckDigit(b2)}')!.qtyMilli,
        1250,
      );
    });
  });
}
