# Dizayn tizimi va UI/UX tamoyillari

## Tamoyillar
1. **Kassa birinchi.** PIN'dan keyin darhol kassa ekrani.
2. **3 harakatda savdo:** skaner → To'lash → to'lov turi.
3. **Katta nishonlar:** ≥ 48 dp, kassa asosiy tugmalari ≥ 56 dp, raqamli klaviatura tugmalari ≥ 64 dp.
4. **Bir qarashda tushunarli:** jami summa eng katta matn; qaytim — yashil, katta.
5. **Oddiy o'zbekcha:** "Internet yo'q — savdolar saqlanyapti (12)", "Sinxronizatsiya xatosi" emas.
6. **Xatoni tuzatish oson:** undo toast 5 s; xavfli amalda bitta tasdiq; ortiqcha modal yo'q.
7. **Holat doim ko'rinadi:** internet, printer, smena, navbat.
8. **Tezlik:** ≤ 100 ms javob, animatsiya ≤ 200 ms, skeleton yuklanishda.
9. **Kontrast:** WCAG AA; quyosh tushadigan do'konda o'qiladi; rang yolg'iz ma'no tashimaydi (ikon + matn).
10. **Klaviatura birinchi (Windows):** har asosiy amalning tezkor tugmasi, ekranda yorliq.
11. **Zamonaviy, lekin tinch:** toza tipografiya, yumshoq soyalar, bir xil radius, keraksiz bezaksiz.

## Tokenlar (boshlang'ich; agent Widgetbook'da sinab, yaxshilashi mumkin)
- Shrift: **Inter** (lotin + kirill), raqamlar uchun `tabular figures`.
- O'lchamlar: display 40/48 (jami summa), h1 28, h2 22, h3 18, body 16, small 14, caption 12. Telefonda kassa summasi 32.
- Oraliq: 4, 8, 12, 16, 24, 32, 48.
- Radius: 8 (input), 12 (tugma, karta), 16 (oyna), 999 (badge).
- Ranglar (yorug'): primary `#2563EB`, primary-hover `#1D4ED8`, success `#16A34A`, warning `#D97706`, danger `#DC2626`, background `#F8FAFC`, surface `#FFFFFF`, border `#E2E8F0`, text `#0F172A`, text-secondary `#475569`, muted `#94A3B8`.
- Ranglar (qorong'i): background `#0B1220`, surface `#111827`, border `#1F2937`, text `#F1F5F9`, text-secondary `#CBD5E1`, primary `#3B82F6`, success `#22C55E`, warning `#F59E0B`, danger `#EF4444`.
- Soyalar: 2 daraja (karta, oyna). Harakat: 120 ms (bosish), 200 ms (oyna).

## Breakpoint'lar
- compact < 600 (telefon), medium 600–899 (kichik planshet), expanded ≥ 900 (planshet/desktop), large ≥ 1280 (desktop).

## Komponentlar ro'yxati
Button, IconButton, TextField, SearchField, NumericKeypad, MoneyText, QtyStepper, Card, ListTile, Badge, StatusDot, AppDialog (desktop dialog / telefon bottom sheet), Toast (undo bilan), EmptyState, Skeleton, AppDataTable, ResponsiveScaffold, StatusBar, PinPad, ScanFeedback (yashil/sariq chaqnash).

## Tekshiruv (har ekran uchun)
- [ ] 3 o'lchamda golden test (telefon 390×844, planshet 1024×768, desktop 1440×900), yorug' va qorong'i
- [ ] bo'sh, yuklanish, xato holatlari bor
- [ ] barcha matnlar tarjima faylida, 3 tilda sig'adi (rus matni uzunroq)
- [ ] klaviatura bilan to'liq ishlatsa bo'ladi (desktop)
- [ ] asosiy amal ≤ 3 harakat
- [ ] kontrast AA

## Amalga oshirilishi (`packages/ui`, T-030)
Hamma narsa `package:pos_ui/pos_ui.dart` orqali. Ekranlarda rang, o'lcham, shrift qattiq yozilmaydi — faqat quyidagilar.

**Tokenlar**
- `PosPalette` (`ThemeExtension`, `PosPalette.of(context)`) — semantik ranglar va 2 daraja soya (`cardShadow`, `overlayShadow`). `PosColors` — faqat primitivlar, ekranda ishlatilmaydi.
- `PosTone` (neutral/primary/success/warning/danger) → `palette.tone(t)`: `fill/onFill`, `text` (sirt ustida), `soft/onSoft`.
- `PosTypography` (Inter 4.1, OFL; display 48/40/32 `tabular` raqamlar, h1 28, h2 22, h3 18, body 16, small 14, caption 12), `PosSpacing`, `PosRadius`, `PosSizes` (48/56/64), `PosMotion` (120/200 ms), `PosWindowSize` (breakpoint'lar).
- `PosTheme.light()/dark({platform})` — Material komponentlari ham tokenlar bilan bezatilgan.
- `PosFormat` — `money(tiyin, currency:)` → `125 000 so'm` (NBSP), `qty(milli, weighted:)` → `1,250`. Valyuta/birlik nomi tarjimadan.

**WCAG AA uchun rang tuzatishlari** (boshlang'ich ro'yxatdan farqi, `test/pos_theme_test.dart` har juftlikni ≥ 4,5:1 tekshiradi):
- Oq matnli success/warning tugmalari: `#15803D` / `#B45309` (`#16A34A`/`#D97706` oq bilan 3,3/3,2 edi).
- Qorong'i mavzu: to'ldirilgan primary `#2563EB` (oq matn 5,2), matn/fokus sifatida `#60A5FA`; success/warning/danger matni `#22C55E`/`#F59E0B`/`#F87171`.
- Ikkinchi darajali izoh (placeholder) `#64748B` (yorug'), `#94A3B8` (qorong'i). `#94A3B8` yorug'da faqat o'chiq holat uchun.

**Komponentlar** (barchasi `Pos` prefiksli): `PosButton` (+`PosKeycap`), `PosIconButton` (tooltip majburiy), `PosTextField`, `PosSearchField`, `PosNumericKeypad`, `PosMoneyText` (`total` — o'lchamga qarab 32/40/48), `PosQtyStepper`, `PosCard`, `PosListTile`, `PosBadge`, `PosStatusDot`, `PosDialog` + `showPosDialog` (telefonda bottom sheet; **faqat mazmun suriladi — sarlavha va tugmalar har doim ko'rinadi**, T-091), `PosToast` + `showPosToast` (5 s, undo), `PosEmptyState`, `PosSkeleton`/`PosSkeletonListTile`, `PosDataTable` (tor ekranda gorizontal suriladi), `PosResponsiveScaffold` (+`PosDestination`), `PosStatusBar` (+`PosStatusItem`), `PosPinPad` (fizik klaviatura ham), `PosScanFeedback` (+controller).
Komponentlar ichida foydalanuvchi matni yo'q: yorliq, tooltip, xato matni parametr sifatida (tarjimadan) beriladi.

**Katalog va golden testlar.** Har komponent guruhi `packages/ui/widgetbook/lib/galleries/` da galereya (barcha holatlar) — Widgetbook'da "All states", golden testlar ham aynan shularni chizadi: `packages/ui/widgetbook/test/goldens/<galereya>/<phone|tablet|desktop>_<light|dark>.png`. Qayta yaratish: `make ui-goldens` (faqat Windows — CI ham Windows'da, 0005).
