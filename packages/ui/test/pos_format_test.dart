import 'package:flutter_test/flutter_test.dart';
import 'package:pos_ui/pos_ui.dart';

const String _sp = PosFormat.nbsp;
const String _minus = PosFormat.minus;

void main() {
  group('groupDigits', () {
    test('groups by thousands with NBSP', () {
      expect(PosFormat.groupDigits(0), '0');
      expect(PosFormat.groupDigits(999), '999');
      expect(PosFormat.groupDigits(1000), '1${_sp}000');
      expect(PosFormat.groupDigits(125000), '125${_sp}000');
      expect(PosFormat.groupDigits(1234567), '1${_sp}234${_sp}567');
      expect(PosFormat.groupDigits(-45000), '${_minus}45${_sp}000');
    });
  });

  group('money', () {
    test('whole som without fraction', () {
      expect(
        PosFormat.money(12500000, currency: "so'm"),
        "125${_sp}000${_sp}so'm",
      );
      expect(PosFormat.money(0, currency: "so'm"), "0${_sp}so'm");
    });

    test('tiyin shown with comma', () {
      expect(
        PosFormat.money(12500050, currency: "so'm"),
        "125${_sp}000,50${_sp}so'm",
      );
      expect(PosFormat.moneyAmount(5), '0,05');
    });

    test('negative', () {
      expect(PosFormat.moneyAmount(-150000), '${_minus}1${_sp}500');
      expect(PosFormat.moneyAmount(-1), '${_minus}0,01');
    });

    test('large amounts stay exact (int, no double)', () {
      expect(
        PosFormat.moneyAmount(999999999999900),
        '9${_sp}999${_sp}999${_sp}999${_sp}999',
      );
    });
  });

  group('qty', () {
    test('pieces', () {
      expect(PosFormat.qty(3000), '3');
      expect(PosFormat.qty(1500), '1,5');
      expect(PosFormat.qty(1250), '1,25');
      expect(PosFormat.qty(1000000), '1${_sp}000');
    });

    test('weighted always 3 decimals', () {
      expect(PosFormat.qty(1250, weighted: true), '1,250');
      expect(PosFormat.qty(250, weighted: true), '0,250');
      expect(PosFormat.qty(2000, weighted: true), '2,000');
    });

    test('negative and unit', () {
      expect(PosFormat.qty(-2000), '${_minus}2');
      expect(
        PosFormat.qtyWithUnit(1250, unit: 'kg', weighted: true),
        '1,250${_sp}kg',
      );
    });
  });
}
