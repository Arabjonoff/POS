# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-020 Platforma admin API
- Branch: feat/T-020-platform-api
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Spec `docs/specs/platform-api.md` (endpointlar, onboarding, audit qoidasi, statistika formulalari)
- [x] 2. `apps/platform_admin`: AdminAuditLog (o'zgarmas) + `audit()` yordamchisi; migratsiya; admin
- [ ] 3. Tenantlar: ro'yxat/karta, onboarding (tenant + ega + obuna, vaqtinchalik parol), tahrir, bloklash, obuna sozlamalari, xodimlar va parol tiklash, sinxron hodisalari
- [ ] 4. Tariflar CRUD (o'chirish = nofaol), to'lovlar (kiritish, bekor qilish, ro'yxat), qurilmalar (ro'yxat, bloklash)
- [ ] 5. Statistika (faol, sinov, MRR, shu oy tushum, 7 kunda tugaydiganlar, sinxronlanmagan qurilmalar) + audit jurnali ro'yxati
- [ ] 6. Testlar: tenant foydalanuvchisi 403, har o'zgarish auditda (oldin/keyin), onboarding, to'lov/bekor, statistika qiymatlari
- [ ] 7. openapi + schema.d.ts; lint/test; PROGRESS/ROADMAP; PR, CI, merge

## Oxirgi bajarilgan ish
2-qadam: `apps/platform_admin` — AdminAuditLog (AppendOnly), `audit.py` (audit(), snapshot() — sirlarsiz), migratsiya 0001, admin.

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
3-qadam: `backend/apps/platform_admin/services.py` (onboard_tenant, temp_password, block/unblock, update_subscription, reset_password) + serializers + TenantViewSet/UserResetView + urls `platform/`.

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
