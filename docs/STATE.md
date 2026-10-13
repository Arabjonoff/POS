# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-002 Docker Compose
- Branch: feat/T-002-docker-compose
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14 02:11

## Qadamlar (vazifa ichida)
- [x] 1. backend/Dockerfile (+ .dockerignore)
- [ ] 2. apps/admin/Dockerfile.dev (+ .dockerignore)
- [ ] 3. docker-compose.yml: postgres 16, redis 7, backend, admin; volume, healthcheck, sozlanadigan portlar
- [ ] 4. .env.example portlari, README/Makefile
- [ ] 5. Tekshiruv: docker compose up -d → /api/health/ ok, admin ochiladi
- [ ] 6. PR, merge

## Oxirgi bajarilgan ish
Dockerfile'lar, docker-compose.yml, .env.example portlari yozildi; pos-pg-dev o'chirildi (endi compose postgres 127.0.0.1:55432).

## Keyingi aniq harakat
5-qadam: docker compose up -d --build (Ishlab turgan: compose build)

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: pos-pg-dev konteyner (postgres:16, 127.0.0.1:55432) — testlar uchun
- Yiqilayotgan testlar: —

## Eslatmalar
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*) tomonidan band. Ularni to'xtatma! POS lokal portlari: postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub; `uv run` yoki `py -3.12` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
