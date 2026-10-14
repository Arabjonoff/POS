# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-017 Savdo, smena, qaytarish
- Branch: feat/T-017-sales-shifts
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Spec `docs/specs/sales-api.md` (smena, savdo, to'lov, qaytarish, pul harakati; tekshiruvlar; kutilayotgan naqd; REST faqat o'qish)
- [x] 2. `apps/sales` modellari: Shift, Sale (+Item, +Payment), Refund (+Item), CashMovement; `DebtEntry.shift` (customers 0002); migratsiya; admin
- [x] 3. `services/shifts.py`: open_shift, close_shift (expected_cash), record_cash_movement, shift_report (X/Z)
- [x] 4. `services/sales.py`: record_sale — tekshiruv (summalar, to'lovlar, tenant), StockMovement(−), DebtEntry (nasiya)
- [x] 5. `services/refunds.py`: record_refund — qoldiq miqdor, summa, StockMovement(+), qarz kamayishi, savdo holati
- [ ] 6. REST (faqat o'qish): `/shifts/` (+report), `/sales/`, `/refunds/`, `/cash-movements/`; kassir faqat o'zinikini ko'radi
- [ ] 7. Testlar: savdo → qoldiq va qarz, qaytarish → teskari harakat, summalar xatosi, smena hisob-kitobi, izolyatsiya, huquqlar
- [ ] 8. openapi + schema.d.ts; lint/test; PROGRESS/ROADMAP; PR, CI, merge

## Oxirgi bajarilgan ish
5-qadam: `services/refunds.py` — record_refund (qator qoldig'i, proporsional summa + oxirgi qismda qoldiq, chek chegirmasi ulushi, to'liq qaytarishda sale.total − oldingilar, debt cheklovi, StockMovement(+), record_refund_debt, Sale.status).

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
6-qadam: `backend/apps/sales/serializers.py`, `views.py` (ShiftViewSet + report, SaleViewSet, RefundViewSet, CashMovementViewSet — ReadOnly, kassir faqat o'zinikini), `urls.py`, `config/urls.py`.

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
