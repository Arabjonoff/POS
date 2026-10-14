# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-030 Dizayn tizimi (packages/ui)
- Branch: feat/T-030-design-system
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [ ] 1. Tokenlar: palitra (ThemeExtension), Inter shrifti, tipografiya, oraliq, radius, soya, harakat, breakpoint + kontrast (WCAG AA) testi
- [ ] 2. To'liq ThemeData (komponent mavzulari) + summa/miqdor formatlash
- [ ] 3. Komponentlar 1: Button, IconButton, TextField, SearchField, Card, ListTile, Badge, StatusDot
- [ ] 4. Komponentlar 2: MoneyText, QtyStepper, NumericKeypad, PinPad
- [ ] 5. Komponentlar 3: Dialog/Sheet, Toast, EmptyState, Skeleton, ScanFeedback
- [ ] 6. Komponentlar 4: DataTable, StatusBar, ResponsiveScaffold
- [ ] 7. Widgetbook: har komponent galereyasi (barcha holatlar) + use-case'lar
- [ ] 8. Golden testlar (3 o'lcham × 2 mavzu) + docs/screenshots/T-030
- [ ] 9. analyze/format/test yashil, PR, merge, ROADMAP/PROGRESS

## Oxirgi bajarilgan ish
T-030 boshlandi: branch yaratildi, qadamlar yozildi.

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
Qadam 1: packages/ui/lib/src/tokens/ (pos_palette.dart, pos_typography.dart, ...) va packages/ui/assets/fonts/Inter-*.ttf.

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: docker compose (pos-*) — 8100, 3100
- Yiqilayotgan testlar: —

## Eslatmalar
<!-- Keyingi sessiya bilishi kerak bo'lgan narsa: topilgan muammo, vaqtinchalik yechim, nima sinab ko'rildi va ishlamadi -->
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*, twf-local-*) tomonidan band. Ularni to'xtatma! POS lokal portlari (.env): postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub, `py -3.12` yo'q; `cd backend && uv run python` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
- Testlar `.env` ni o'qimaydi: `cd backend && DATABASE_URL=postgres://pos:pos@127.0.0.1:55432/pos uv run pytest`.
- 2026-10-14: elektr uzilishi `.git/config` ni nol baytlar bilan buzgan edi; foydalanuvchi qayta tikladi (`[core]` + `origin`).
- Docker Desktop o'chiq bo'lishi mumkin: `C:\Users\Muhammadi\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe` ni ishga tushir, `docker info` javob berguncha kut.
