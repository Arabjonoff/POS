# POS — mahalla do'konlari uchun kassa va ombor tizimi

Obuna asosidagi kassa (POS) va ombor tizimi: internet yoki elektr uzilsa ham savdo to'xtamaydi, ma'lumot yo'qolmaydi.

| Qism | Texnologiya | Papka |
|---|---|---|
| Backend API | Django 5.2 + DRF + PostgreSQL 16 | `backend/` |
| Kassa ilovasi | Flutter (Windows, Android, iOS), Drift (SQLite) | `apps/pos/` |
| Dizayn tizimi | Flutter paket + Widgetbook | `packages/ui/` |
| Admin dashboard | Next.js + TypeScript + Tailwind | `apps/admin/` |
| API klientlar | OpenAPI'dan generatsiya | `packages/api_client_dart/`, `apps/admin/src/api/` |

## Kerakli dasturlar
Git, Docker Desktop, [uv](https://docs.astral.sh/uv/) (Python 3.12 ni o'zi o'rnatadi), Node.js 20+, Flutter (stable), GNU Make.
Batafsil: `docs/AGENT_SETUP.md`.

## Ishga tushirish
```sh
cp .env.example .env      # bir marta
make up                   # postgres, redis, backend (:8000), admin (:3000)
make migrate              # baza jadvallari
make pos-get              # Flutter bog'liqliklari
cd apps/pos && flutter run -d windows
```
- API hujjatlari: http://localhost:8000/api/docs/
- Admin dashboard: http://localhost:3000
- Port band bo'lsa — `.env` da `POSTGRES_PORT`, `REDIS_PORT`, `BACKEND_PORT`, `ADMIN_PORT` ni o'zgartiring va `make up` ni qayta bering.
- Backend konteyneri ishga tushganda migratsiyalarni o'zi qo'llaydi.

## Buyruqlar
`make help` — hamma buyruqlar ro'yxati. Asosiylari:

| Buyruq | Nima qiladi |
|---|---|
| `make up` / `make down` | Docker servislarini yoqish/o'chirish |
| `make backend-test`, `make backend-lint` | Backend testlari va lint |
| `make pos-analyze`, `make pos-test` | Kassa ilovasi tekshiruvi va testlari |
| `make ui-test` | Dizayn tizimi golden testlari |
| `make admin-lint`, `make admin-test`, `make admin-e2e` | Admin tekshiruvlari |
| `make api-clients` | OpenAPI'dan Dart va TS klientlarni yangilash |
| `make lint`, `make test` | Hammasi birdaniga |

## Hujjatlar
| Fayl | Nima |
|---|---|
| `CLAUDE.md` | Loyiha qoidalari (AI agent konstitutsiyasi) |
| `docs/ROADMAP.md` | Vazifalar ro'yxati va holati |
| `docs/specs/` | Har funksiya spec'i |
| `docs/decisions/` | Qabul qilingan qarorlar |
| `docs/STATE.md` | Agent hozir nima ustida ishlayapti (uzilishdan keyin davom etish uchun) |
| `docs/PROGRESS.md` | Bajarilgan ishlar jurnali |
| `docs/QUESTIONS.md` | Loyiha egasiga savollar |
| `docs/user-guide/` | Foydalanuvchi qo'llanmasi (kassir, do'kon egasi) |
| `docs/DEPLOY.md`, `docs/RELEASE.md` | Serverga chiqarish, ilovani chiqarish |
| `docs/resilience.md`, `docs/ui-review.md` | Chidamlilik va UI tekshiruvlari natijalari |
| `docs/AGENT_SETUP.md` | O'rnatish, MCP serverlar, avtomatik sikl |
| `prompts/` | Agent uchun tayyor promptlar |
