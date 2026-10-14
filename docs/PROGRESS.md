# PROGRESS — sessiyalar jurnali

Har vazifa yoki sessiya oxirida agent shu faylning oxiriga yozadi:

```
## YYYY-MM-DD HH:MM — T-XXX <nomi>
- Qilindi: ...
- PR: #N (merged / ochiq)
- Qoldi / keyingi qadam: ...
- Muammo yoki qaror: ...
```

---

## 2026-10-14 — T-001 Monorepo tuzilishi
- Qilindi: papkalar (backend, apps/pos, apps/admin, packages/ui, packages/api_client_dart), .gitignore (.env, logs/), .gitattributes (LF), .editorconfig, .env.example, Dart pub workspace (ildiz pubspec.yaml), Makefile (`make help`), o'zbekcha README.
- PR: T-001 (squash merge)
- Qoldi / keyingi qadam: T-003 Django skeleti (backend `uv` bilan boshqariladi).
- Muammo yoki qaror: Windows'da `python` — Store stub; Python 3.12 `uv` orqali ishlatiladi. CLAUDE.md "Buyruqlar" `make` maqsadlariga moslandi.

## 2026-10-14 — T-003 Django skeleti
- Qilindi: `backend/` (uv, Python 3.12, Django 5.2, DRF, SimpleJWT, drf-spectacular + sidecar, CORS), settings base/dev/test/prod (`DATABASE_URL`), `apps/core`: UUIDv7 (`new_id`), `TimeStampedModel`, `TenantScopedModel`, `SoftDeleteModel`, `TenantScopedViewSet`, pagination, yagona xato formati, `money.py` (half-up) + umumiy vektorlar `testdata/money_rounding.json`; `/api/health/`, `/api/schema/`, `/api/docs/`. 43 test yashil, ruff toza.
- PR: T-003 (squash merge)
- Qoldi / keyingi qadam: T-005 Next.js admin, T-006 Flutter skeleti, keyin T-002/T-004.
- Muammo yoki qaror: Windows'da `localhost` orqali Postgres'ga ulanish osilib qoladi (IPv6) — har doim `127.0.0.1` ishlatiladi. TenantScopedViewSet haqiqiy model bilan testi T-010 da (Tenant modeli shu yerda paydo bo'ladi).

## 2026-10-14 — T-005 Next.js admin skeleti
- Qilindi: `apps/admin` — Next.js 16.4 (App Router, TS strict), Tailwind 4, shadcn/ui (base-nova, base-ui), TanStack Query, next-themes (yorug'/qorong'i/tizim), next-intl (uz/ru, cookie), Inter (fontsource — oflayn build), sidebar + header layout, `src/api` (openapi-typescript + openapi-fetch, `npm run api:generate`), Vitest (7 test) va Playwright smoke (3 test).
- PR: T-005 (squash merge)
- Qoldi / keyingi qadam: T-006 Flutter skeleti; keyin T-002 (compose), T-004 (CI).
- Muammo yoki qaror: `cacheComponents` o'chirildi (admin to'liq dinamik, cookie'dagi til bilan zid). `@vitejs/plugin-react` babel 8 bilan peer konflikt — kerak emas (oxc JSX). Lokal 3000 band, e2e porti 3100. `backend/openapi.yaml` repoda saqlanadi (klient generatsiyasi uchun manba).

## 2026-10-14 — T-006 Flutter skeleti
- Qilindi: `apps/pos` (Windows, Android, iOS; org `uz.zellypos`), Riverpod 3, go_router, Drift (`AppDatabase` + `LocalSettings`), gen-l10n ARB (uz, uz_Cyrl, ru), `packages/ui` (rang tokenlari, `PosTheme.light/dark`), Widgetbook (`packages/ui/widgetbook`, 3 viewport, 2 mavzu), ildizda umumiy `analysis_options.yaml` (very_good_analysis). Testlar: pos 5, ui 2, widgetbook 2; analyze toza; `flutter build windows` muvaffaqiyatli, ilova ochildi.
- PR: T-006 (squash merge)
- Qoldi / keyingi qadam: T-002 Docker Compose, T-004 CI. `make api-clients` Dart qismi (generator tanlovi) — birinchi haqiqiy API bilan (T-011).
- Muammo yoki qaror: Lokal Flutter 3.41.7 / Dart 3.11; eng yangi paketlar (riverpod 3.4, drift 2.35, widgetbook 3.25) Dart 3.12 talab qiladi — mos versiyalar tanlandi, Flutter global yangilanmadi (boshqa loyihalarga ta'sir qilmasin). CI ham 3.41.7 ga pin qilinadi. `flutter test` Windows'da SQLite uchun `winsqlite3.dll` ishlatadi (`test/helpers/sqlite.dart`).

## 2026-10-14 — T-002 Docker Compose
- Qilindi: `docker-compose.yml` (postgres:16, redis:7, backend — Django runserver + avtomatik migrate, admin — Next.js dev), volume'lar, healthcheck'lar, `.env` orqali sozlanadigan portlar; `backend/Dockerfile` (uv, /opt/venv, gunicorn CMD, HEALTHCHECK), `apps/admin/Dockerfile.dev`; README'ga port eslatmasi. Tekshirildi: `docker compose up -d --build` → `/api/health/` `{"status":"ok"}`, admin 200, `/api/docs/` 200.
- PR: T-002 (squash merge)
- Qoldi / keyingi qadam: T-004 CI (GitHub Actions); keyin T-010 Tenant va Store.
- Muammo yoki qaror: elektr uzilishi initdb vaqtida `pg_hba.conf` oxirini nol baytlar bilan buzgan — fayl qo'lda tuzatildi (volume o'chirilmadi). Bu kompyuterda standart portlar band, POS lokal portlari .env da: 55432/56379/8100/3100.

## 2026-10-14 — T-004 CI (GitHub Actions)
- Qilindi: `.github/workflows/ci.yml` — `changes` (paths-filter) + `backend` (postgres service, ruff, makemigrations --check, openapi.yaml dolzarbligi, pytest) + `flutter` (windows-latest, 3.41.7, analyze, format, test) + `admin` (schema.d.ts dolzarbligi, lint, typecheck, Vitest, build, Playwright). Qaror `docs/decisions/0005-ci.md`. PR'da 4 tekshiruv yashil.
- PR: #6 (squash merge)
- Qoldi / keyingi qadam: T-010 Tenant va Store.
- Muammo yoki qaror: CI'da `LayoutProps` topilmadi — lokal `.next/types` eski build'dan qolgan edi; `typecheck` endi `next typegen && tsc --noEmit`. Flutter Windows runner'da (golden'lar lokal Windows'da yaratiladi).
