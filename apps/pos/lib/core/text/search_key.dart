/// Qidiruv kaliti: lotin va kirill yozuvi bir xil kalitga keladi
/// (`docs/specs/pos-screen.md`: "lotin/kirill farqi yo'q").
///
/// - kichik harf;
/// - kirill (o'zbek va rus) → o'zbek lotin: `Олма` → `olma`, `Чой` → `choy`,
///   `Ўрик` → `orik`, `Молоко` → `moloko`;
/// - tutuq belgilari (`'`, `ʻ`, `ʼ`, `‘`, `’`, `` ` ``) olib tashlanadi —
///   `o'rik` = `orik` = `ўрик`;
/// - `h` = `x`;
/// - harf va raqamdan boshqa belgilar — bo'shliq, bo'shliqlar bitta.
abstract final class SearchKey {
  static const Map<String, String> _cyrillic = {
    'а': 'a',
    'б': 'b',
    'в': 'v',
    'г': 'g',
    'ғ': 'g',
    'д': 'd',
    'е': 'e',
    'ё': 'yo',
    'ж': 'j',
    'з': 'z',
    'и': 'i',
    'й': 'y',
    'к': 'k',
    'қ': 'q',
    'л': 'l',
    'м': 'm',
    'н': 'n',
    'о': 'o',
    'п': 'p',
    'р': 'r',
    'с': 's',
    'т': 't',
    'у': 'u',
    'ў': 'o',
    'ф': 'f',
    'х': 'x',
    'ҳ': 'h',
    'ц': 's',
    'ч': 'ch',
    'ш': 'sh',
    'щ': 'sh',
    'ъ': '',
    'ы': 'i',
    'ь': '',
    'э': 'e',
    'ю': 'yu',
    'я': 'ya',
  };

  static const String _apostrophes = "'`ʻʼ‘’";

  static String of(String text) {
    final buffer = StringBuffer();
    var space = true;
    for (final rune in text.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final latin = _cyrillic[ch];
      if (latin != null) {
        buffer.write(latin);
        space = false;
      } else if (_apostrophes.contains(ch)) {
        continue;
      } else if (_isLetterOrDigit(rune)) {
        buffer.write(ch);
        space = false;
      } else if (!space) {
        buffer.write(' ');
        space = true;
      }
    }
    // `h` va `x` ko'p adashtiriladi (`hurmo`/`xurmo`) — bitta harf.
    return buffer.toString().trimRight().replaceAll('h', 'x');
  }

  static bool _isLetterOrDigit(int rune) =>
      (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x61 && rune <= 0x7a) ||
      // Boshqa alifbolar (masalan, `ñ`) — o'zgarishsiz.
      (rune >= 0xc0 && rune != 0xd7 && rune != 0xf7);
}
