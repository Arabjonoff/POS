import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/text/phone.dart';

void main() {
  test('phone is normalized like the server does', () {
    for (final raw in [
      '90 123 45 67',
      '901234567',
      '+998 (90) 123-45-67',
      '998901234567',
      '+998901234567',
    ]) {
      expect(normalizePhone(raw), '+998901234567', reason: raw);
    }
  });

  test('blank is allowed (phone is optional); garbage is rejected', () {
    expect(normalizePhone(''), '');
    expect(normalizePhone('   '), '');
    for (final raw in ['12345', '+7 901 234 56 78', '90 123 45 6x', '+99890']) {
      expect(normalizePhone(raw), isNull, reason: raw);
    }
  });
}
