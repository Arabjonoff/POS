# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-011 Foydalanuvchilar va autentifikatsiya
- Branch: feat/T-011-auth
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Qaror `docs/decisions/0006-users-pin.md` (custom User, PIN = PBKDF2-SHA256 120k Django formati, kassir telefoni ixtiyoriy) + `auth-roles.md` aniqlashtirish
- [x] 2. `apps/accounts`: User (AbstractBaseUser+PermissionsMixin, UUIDv7, tenant null faqat platform_admin, phone unique null, role, pin_hash), UserManager, `pins.py` (PinHasher), `AUTH_USER_MODEL`, migratsiya; dev bazani qayta yaratish (bo'sh edi)
- [ ] 3. Endpoint'lar: `/api/v1/auth/login`, `/refresh`, `/me`; login throttle
- [ ] 4. `permissions.py` (IsPlatformAdmin, IsOwner, IsManagerOrOwner, IsTenantMember) + `/api/v1/users/` (read-only, manager+)
- [ ] 5. Testlar: model, PIN vektorlari `testdata/pin_hash.json`, login/refresh/me, rollar, tenant izolyatsiyasi
- [ ] 6. openapi.yaml + admin schema.d.ts yangilash; lint/test; PR, CI, merge

## Oxirgi bajarilgan ish
T-010 merge qilindi (#7). T-011 branch ochildi.

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
3-qadam: `backend/apps/accounts/serializers.py`, `views.py` (LoginView, RefreshView, MeView), `urls.py`; config/urls.py ga ulash; THROTTLE_RATES auth.

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: docker compose (pos-*) — 8100, 3100. **Dev baza (pos_pgdata) eski `auth.User` migratsiyalari bilan** — `AUTH_USER_MODEL` o'zgargani uchun backend konteyneri `migrate` da InconsistentMigrationHistory beradi. Baza bo'sh (0 user). Tozalash (DROP SCHEMA) foydalanuvchi ruxsati bilan qilinadi; agent o'zi qilmaydi.
- Yiqilayotgan testlar: —

## Eslatmalar
<!-- Keyingi sessiya bilishi kerak bo'lgan narsa: topilgan muammo, vaqtinchalik yechim, nima sinab ko'rildi va ishlamadi -->
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*, twf-local-*) tomonidan band. Ularni to'xtatma! POS lokal portlari (.env): postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub, `py -3.12` yo'q; `cd backend && uv run python` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
- Docker Desktop o'chiq bo'lishi mumkin: `C:\Users\Muhammadi\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe` ni ishga tushir, `docker info` javob berguncha kut.
