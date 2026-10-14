# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-016 Mijozlar va nasiya
- Branch: feat/T-016-customers-debts
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Spec `docs/specs/customers-api.md` (mijoz, DebtEntry, balans, limit, to'lov, tuzatish, huquqlar, API); savol bo'lsa `QUESTIONS.md`
- [ ] 2. `apps/customers`: Customer (yumshoq o'chirish), DebtEntry (AppendOnlyModel); migratsiya; admin
- [ ] 3. `services.py`: balance, record_debt (sale/refund — T-017 uchun), check_limit, pay_debt, adjust_debt (qulf bilan)
- [ ] 4. API: `/customers/` (balance, search, has_debt, saralash), `/{id}/debt-entries/`, `/{id}/payments/`, `/{id}/adjustments/`
- [ ] 5. Testlar: qarzga sotish + qisman to'lov → balans, limit, ortiqcha to'lov, tuzatish (faqat ega), o'zgarmaslik, izolyatsiya, huquqlar
- [ ] 6. openapi + schema.d.ts; lint/test; PROGRESS/ROADMAP; PR, CI, merge

## Oxirgi bajarilgan ish
1-qadam: spec `docs/specs/customers-api.md`; Q-003 (ortiqcha to'lov — vaqtincha A: rad).

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
2-qadam: `backend/apps/customers/` (apps.py, models.py: Customer + DebtEntry, admin.py), `config/settings/base.py` INSTALLED_APPS, `makemigrations customers`.

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
