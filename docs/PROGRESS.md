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
