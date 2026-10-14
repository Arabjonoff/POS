import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/text/search_key.dart';

void main() {
  test('latin and cyrillic spellings give the same key', () {
    for (final (a, b) in [
      ('Olma', 'Олма'),
      ('Choy', 'Чой'),
      ("O'rik", 'Ўрик'),
      ("G'alla", 'Ғалла'),
      ('Shakar', 'Шакар'),
      ('Yogʻ', 'Йоғ'),
      ('Yod', 'Ёд'),
      ('Xurmo', 'Ҳурмо'),
      ('Hurmo', 'Хурмо'),
      ('Moloko', 'Молоко'),
    ]) {
      expect(SearchKey.of(a), SearchKey.of(b), reason: '$a / $b');
    }
  });

  test('apostrophe variants are ignored', () {
    for (final s in ["o'rik", 'oʻrik', 'oʼrik', 'o‘rik', 'o’rik', 'o`rik']) {
      expect(SearchKey.of(s), 'orik');
    }
  });

  test('lowercase, punctuation to single spaces, digits kept', () {
    expect(SearchKey.of('  Coca-Cola  1,5 L '), 'coca cola 1 5 l');
    expect(SearchKey.of('Non (issiq)'), 'non issiq');
    expect(SearchKey.of(''), '');
  });
}
