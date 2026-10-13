# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-003 Django skeleti
- Branch: feat/T-003-django-skeleton
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
- [ ] 1. backend/pyproject.toml (uv, Python 3.12, Django 5.2, DRF, SimpleJWT, spectacular, cors, psycopg, ruff, pytest) + uv.lock
- [ ] 2. config/ (settings base/dev/test/prod, DATABASE_URL), urls, wsgi/asgi, manage.py
- [ ] 3. apps/core: UUIDv7 id, TimeStampedModel, TenantScopedModel (abstrakt), money yordamchisi (half-up)
- [ ] 4. apps/core: TenantScopedViewSet, pagination, xato formati (exception handler)
- [ ] 5. health endpoint, /api/schema/, /api/docs/
- [ ] 6. Testlar (pytest) + ruff toza
- [ ] 7. PR, merge

## Oxirgi bajarilgan ish
Vazifa boshlandi. Lokal test bazasi: `docker run ... --name pos-pg-dev -p 127.0.0.1:55432:5432 postgres:16`.

## Keyingi aniq harakat
1-qadam: backend/pyproject.toml yozish va `cd backend && uv sync`.

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: pos-pg-dev konteyner (postgres:16, 127.0.0.1:55432)
- Yiqilayotgan testlar: —

## Eslatmalar
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*) tomonidan band. Ularni to'xtatma! POS uchun lokal portlar: postgres 55432, redis 56379, backend 8100, admin 3100 (env orqali).
- `python` buyrug'i Windows Store stub — `uv run` yoki `py -3.12` ishlat.
