# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-002 Docker Compose
- Branch: feat/T-002-docker-compose
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14 (sessiya 2)

## Qadamlar (vazifa ichida)
- [x] 1. backend/Dockerfile (+ .dockerignore)
- [x] 2. apps/admin/Dockerfile.dev (+ .dockerignore)
- [x] 3. docker-compose.yml: postgres 16, redis 7, backend, admin; volume, healthcheck, sozlanadigan portlar
- [x] 4. .env.example portlari, README/Makefile
- [x] 5. Tekshiruv: docker compose up -d → /api/health/ ok, admin ochiladi
- [ ] 6. PR, merge

## Oxirgi bajarilgan ish
Dockerfile'lar, docker-compose.yml, .env.example portlari yozildi; pos-pg-dev o'chirildi (endi compose postgres 127.0.0.1:55432).

## Keyingi aniq harakat
6-qadam: `gh pr create` (feat/T-002-docker-compose → main), CI bo'lmasa lokal tekshiruv yetarli, squash merge; ROADMAP T-002 [x], PROGRESS yozuvi, STATE bo'sh shablon.

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: — (pos-pg-dev o'chirilgan; compose ko'tarilganda postgres 127.0.0.1:55432)
- Yiqilayotgan testlar: —

## Eslatmalar
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*) tomonidan band. Ularni to'xtatma! POS lokal portlari: postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub; `uv run` yoki `py -3.12` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
- Elektr uzilishi initdb vaqtida pos_pgdata ichidagi pg_hba.conf oxirini nol baytlar bilan buzgan edi ("no pg_hba.conf entry for host 172.x"). Tuzatildi: nol baytlar olib tashlandi, `host all all all scram-sha-256` qo'shildi, `pg_reload_conf()`.
- `py -3.12` bu kompyuterda yo'q — Python skriptlar uchun `cd backend && uv run python` ishlat.
- Docker Desktop o'chiq bo'lishi mumkin: `C:\Users\Muhammadi\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe` ni ishga tushir, `docker info` javob berguncha kut.
