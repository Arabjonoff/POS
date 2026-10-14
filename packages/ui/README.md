# pos_ui — dizayn tizimi

Tokenlar (rang, tipografiya, oraliq, radius, soya, harakat), yorug'/qorong'i mavzu va kassa komponentlari.
Spec va komponentlar ro'yxati: `docs/specs/design-system.md` ("Amalga oshirilishi" bo'limi).

```dart
import 'package:pos_ui/pos_ui.dart';

MaterialApp(theme: PosTheme.light(), darkTheme: PosTheme.dark(), ...);
final p = PosPalette.of(context); // semantik ranglar
PosButton(label: l10n.pay, shortcut: 'F12', size: PosButtonSize.xl, onPressed: pay);
PosMoneyText(amount: totalTiyin, currency: l10n.currency, size: PosMoneySize.total);
```

- Testlar: `make ui-test` (`flutter test` bu papkada va `widgetbook/` da — golden'lar o'sha yerda).
- Katalog: `make widgetbook` (Windows) yoki `cd widgetbook && flutter run -d chrome`.
- Golden'larni qayta yaratish: `make ui-goldens` (faqat Windows).
- Shrift: Inter 4.1, SIL OFL 1.1 — `assets/fonts/OFL.txt`.
