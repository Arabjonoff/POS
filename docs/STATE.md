# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-012 Qurilmalar (Device)
- Branch: feat/T-012-devices
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Spec: `docs/specs/devices.md` (token formati, idempotent ro'yxatdan o'tish, chegara, bloklash, xato kodlari)
- [x] 2. `apps/devices`: Device (TenantScopedModel: store, number, name, platform, app_version, last_sync_at, last_seen_at, last_ip, is_blocked, token_hash, registered_by), migratsiya, admin
- [x] 3. `tokens.py` + `authentication.py` (DeviceTokenAuthentication, `Device <token>`, spectacular extension) + `services.register_device`
- [x] 4. API: `POST /api/v1/devices/register/` (owner), `GET /api/v1/devices/` (manager+), `GET /api/v1/devices/me/` (qurilma tokeni)
- [ ] 5. Testlar: chegara, idempotentlik, bloklangan 403, tenant izolyatsiyasi, token turlari aralashmasligi
- [ ] 6. openapi + schema.d.ts; lint/test; PR, CI, merge

## Oxirgi bajarilgan ish
T-013 merge qilindi (#9). T-012 branch ochildi.

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
5-qadam: `backend/apps/devices/tests/test_register.py`, `test_auth.py`.

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: docker compose (pos-*) — 8100, 3100
- Yiqilayotgan testlar: —

## Eslatmalar
<!-- Keyingi sessiya bilishi kerak bo'lgan narsa: topilgan muammo, vaqtinchalik yechim, nima sinab ko'rildi va ishlamadi -->
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*, twf-local-*) tomonidan band. Ularni to'xtatma! POS lokal portlari (.env): postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub, `py -3.12` yo'q; `cd backend && uv run python` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
- Docker Desktop o'chiq bo'lishi mumkin: `C:\Users\Muhammadi\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe` ni ishga tushir, `docker info` javob berguncha kut.
