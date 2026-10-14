# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-018 Sinxronlash API
- Branch: feat/T-018-sync-api
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Spec `docs/specs/sync-api.md` (push formati, statuslar + pending, hodisa → servis jadvali, payloadlar, pull entitylari, ChangeLog, muddati o'tgan pending)
- [x] 2. `apps/sync` modellari: SyncEvent, ChangeLog; migratsiya + mavjud ma'lumot uchun ChangeLog backfill; admin
- [x] 3. ChangeLog yozish: signal'lar (Product, ProductBarcode, Category, Unit, Customer, Supplier, User, Store, DebtEntry, ProductStock) + `_bump_cache` (update()) uchun aniq yozuv
- [x] 4. `handlers.py`: hodisa turi → servis (shift/cash/sale/refund/debt.paid/customer/supplier/product/receipt/inventory); xatolarni natijaga aylantirish
- [x] 5. Push: `POST /api/v1/sync/push` (qurilma tokeni; idempotent; har hodisa alohida tranzaksiya; pending qayta urinish)
- [x] 6. Pull: `GET /api/v1/sync/pull?cursor=&limit=` (ChangeLog, entity serializerlar, subscription, server_time)
- [ ] 7. Testlar: sync.md server mezonlari 1–4 + handlerlar, pull kursori, izolyatsiya
- [ ] 8. openapi + schema.d.ts; lint/test; PROGRESS/ROADMAP; PR, CI, merge

## Oxirgi bajarilgan ish
6-qadam: pull — `apps/sync/pull.py` (entity serializerlari, dedupe, `(txid, seq)` kursor — `apps/sync/db.py`, migratsiya 0003), `GET /api/v1/sync/pull/`, `subscription_snapshot` billing'ga chiqarildi (devices/me ham ishlatadi).

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
7-qadam: `backend/apps/sync/tests/` — conftest (qurilma + token client), test_push.py (mezon 1–4, statuslar, handlerlar), test_pull.py (kursor, dedupe, delete, entitylar, izolyatsiya).

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
