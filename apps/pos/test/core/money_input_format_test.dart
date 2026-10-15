import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/money/grouped_money_formatter.dart';
import 'package:pos_app/features/products/product_card.dart'
    show formatMoneyInput, parseMoneyTiyin;

void main() {
  const f = DecimalMoneyFormatter();

  TextEditingValue type(String text, {int? cursor, String old = ''}) =>
      f.formatEditUpdate(
        TextEditingValue(text: old),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: cursor ?? text.length),
        ),
      );

  test('groups thousands, keeps up to 2 decimals (audit UI-P2)', () {
    expect(type('1500000').text, '1 500 000');
    expect(type('12500,5').text, '12 500,5');
    expect(type('12500.50').text, '12 500,50');
    expect(type(',5').text, '0,5');
    expect(type('00120').text, '120');
    expect(type('12a3').text, '123');
    // 3-kasr xonasi va 12 dan ortiq raqam — rad (eski qiymat qoladi).
    expect(type('1,234', old: '1,23').text, '1,23');
    expect(type('1' * 13, old: '1').text, '1');
  });

  test('cursor stays after the same digit when editing in the middle', () {
    // "1 500 000" ning "1" dan keyin "2" yozildi: "12 500 000".
    final v = type('12 500 000', cursor: 2);
    expect(v.text, '12 500 000');
    expect(v.selection.baseOffset, 2);
    // Oxirgi raqam o'chirildi: "150 000" → kursor oxirida.
    final del = type('1 500 00');
    expect(del.text, '150 000');
    expect(del.selection.baseOffset, del.text.length);
  });

  test('formatted text round-trips to tiyin', () {
    for (final tiyin in [0, 100, 450000, 150000000, 1250050, 99]) {
      expect(parseMoneyTiyin(formatMoneyInput(tiyin)), tiyin);
    }
    expect(formatMoneyInput(150000000), '1 500 000');
    expect(formatMoneyInput(1250050), '12 500,50');
  });
}
