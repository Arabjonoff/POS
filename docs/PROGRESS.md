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

## 2026-10-14 — T-010 Tenant va Store
- Qilindi: `apps/tenants` — `Tenant` (name, owner_phone `+998XXXXXXXXX`, address, timezone, default_locale, notes, is_blocked, blocked_reason) va `Store` (TenantScopedModel); yangi tenantga bitta Store (post_save signal, `raw` da emas); Django admin (Tenant + Store inline). `apps/core/phone.py` — `normalize_phone`/`validate_phone`. Umumiy fixture'lar `make_tenant`, `tenant`, `other_tenant` (`backend/conftest.py`). TenantScopedViewSet Store bilan izolyatsiya testi (list/retrieve/update/create). 72 test yashil.
- PR: T-010 (squash merge)
- Qoldi / keyingi qadam: T-011 Foydalanuvchilar va autentifikatsiya (telefon normalizatsiyasi tayyor).
- Muammo yoki qaror: Tenant `status` saqlanmaydi — Subscription (T-013) va `is_blocked` dan hisoblanadi; `data-model.md` shunga moslandi. Tenant o'chirilmaydi (Store PROTECT).

## 2026-10-14 — T-011 Foydalanuvchilar va autentifikatsiya
- Qilindi: `apps/accounts` — `User` (`AUTH_USER_MODEL`, UUIDv7, telefon bilan kirish, rollar platform_admin/owner/manager/cashier, `tenant` faqat platform_admin'da bo'sh — DB constraint, kassir telefonsiz va parolsiz), PIN hash `pins.py` (PBKDF2-SHA256 120k, Django formati) + umumiy vektorlar `testdata/pin_hash.json`; `/api/v1/auth/login/`, `/refresh/` (rotatsiya, nofaol user rad), `/me/`, `/api/v1/users/` (read-only, manager+); permission klasslari (IsPlatformAdmin, IsOwner, IsManagerOrOwner, IsTenantMember); auth throttle 20/min; Django admin (faqat platform_admin). Fixture'lar `make_user`, `owner`, `client_as`. 149 test yashil. openapi.yaml va admin `schema.d.ts` yangilandi. Qaror 0006.
- PR: T-011 (squash merge)
- Qoldi / keyingi qadam: T-012 Qurilmalar (T-013 ga ham bog'liq — avval T-013 Tariflar va obuna). Xodim qo'shish/tahrirlash API (PIN o'rnatish) hali yo'q — kassa xodimlar ekrani bilan birga.
- Muammo yoki qaror: `AUTH_USER_MODEL` almashgani uchun lokal dev baza (pos_pgdata, bo'sh) eski migratsiya tarixi bilan mos emas — backend konteyneri `migrate` da InconsistentMigrationHistory beradi; tozalash foydalanuvchi ruxsati bilan (`DROP SCHEMA public CASCADE`). Python `\d` Unicode raqamlarni ham oladi — PIN/telefon `[0-9]` bilan tekshiriladi.

## 2026-10-14 — T-013 Tariflar va obuna
- Qilindi: `apps/billing` — `Plan` (narx tiyin, max_devices, max_users, features), `Subscription` (tenant 1:1, trial_ends_at, paid_until, grace_days 3, offline_days 7, kesh `status`), `SubscriptionPayment` (o'zgarmas; bekor qilish — teskari yozuv, `previous_paid_until` qaytariladi). `status.compute_status` (sof funksiya, kun aniqligida, tenant vaqt zonasi), `add_months` (oy oxiri qisqartiriladi), `services` (start_subscription, record_payment, reverse_payment, subscription_status, refresh_status), `manage.py update_subscriptions`. Admin (to'lovlar faqat ko'rish). Fixture'lar `make_plan`, `plan`. 208 test yashil (14 ta parametrlangan holat).
- PR: T-013 (squash merge)
- Qoldi / keyingi qadam: T-012 Qurilmalar (max_devices, qurilma tokeni). `max_users` tekshiruvi — xodim qo'shish API bilan. To'lov kiritish API va audit jurnali — T-020. Cron (`update_subscriptions`) — deploy (T-090).
- Muammo yoki qaror: Q-001 (sinovdan keyin ham grace — A) va Q-002 (sinov ichida to'lov sinov oxiridan boshlanadi — B) vaqtincha tanlandi, `QUESTIONS.md` da javob kutilmoqda. Sana semantikasi `subscription-billing.md` "Sanalar" bo'limida.

## 2026-10-14 — T-012 Qurilmalar (Device)
- Qilindi: `apps/devices` — `Device` (tenant ichida tartib raqami `number` → `D{n}`, store, platform, app_version, last_sync_at/last_seen_at/last_ip, is_blocked, token_hash), qurilma tokeni (`dev_` + token_urlsafe(32), serverda sha256), `DeviceTokenAuthentication` (`Authorization: Device <token>`, spectacular extension), `register_device` (tenant qulfi, max_devices chegarasi, klient `id` bilan idempotent qayta ro'yxat — yangi token, limit sarflanmaydi). API: `POST /devices/register/` (owner), `GET /devices/` (manager+), `GET /devices/me/` (qurilma; obuna holati, server vaqti). `DomainError` ga `details`. Spec `docs/specs/devices.md`. 238 test yashil.
- PR: T-012 (squash merge)
- Qoldi / keyingi qadam: T-014 Katalog API. Qurilmani ega o'zi bloklashi — T-020/ilova sozlamalari.
- Muammo yoki qaror: token turlari aralashmaydi — qurilma tokeni default autentifikatsiyada yo'q, faqat qurilma endpoint'larida (foydalanuvchi endpoint'ida 401). Bloklangan qurilma chegaraga kirmaydi, raqami qayta ishlatilmaydi. Obuna readonly/blocked bo'lsa ham qurilma ulanadi (sinxron ishlashi uchun).

## 2026-10-14 — T-014 Katalog API
- Qilindi: `apps/catalog` — Unit (yangi tenantga standart birliklar: signal + data migratsiya; nomi klient tarjimasida), Category (yumshoq o'chirish, ichkilari bilan; tovarlar kategoriyasiz qoladi), Product (pul/miqdor bigint, vaznli + PLU 5 raqam, IKPU, tez tugma; DELETE = nofaol), ProductBarcode (tenant ichida unique, yumshoq o'chirish, asosiysi birinchi), PriceHistory (yaratish va narx o'zgarishida). API: `/units/`, `/categories/`, `/products/` (search/category/is_active/quick_button filtrlari, `markup_bp`), `/products/by-barcode/{code}/`. `apps/core/fields.py` — `StrictIntegerField`/`money_field` (150.0, "150", true rad). `barcodes.py` — normalizatsiya, EAN-8/UPC-A/EAN-13 nazorat raqami. Spec `catalog-api.md`. 324 test yashil.
- PR: T-014 (squash merge)
- Qoldi / keyingi qadam: T-015 Ombor (StockMovement, kirim, inventarizatsiya). Excel import — T-051.
- Muammo yoki qaror: `barcode.md` dagi tarozi misoli `2012345012503` nazorat raqami noto'g'ri edi — `2012345012509` ga tuzatildi (T-040 Dart testlari shundan foydalanadi). Q-001/Q-002 egasi tomonidan tasdiqlandi (A, B).

## 2026-10-14 — T-015 Ombor (StockMovement, kirim, inventarizatsiya)
- Qilindi: `apps/inventory` — `StockMovement` (AppendOnlyModel: faqat qo'shiladi; qoldiq manbasi), `ProductStock` (kesh, harakat bilan bir tranzaksiyada; `manage.py rebuild_stock`), `Supplier` (yumshoq o'chirish), `StockReceipt`(+Item: qoralama → post → harakatlar, tannarx/sotish narxi + PriceHistory; teskari kirim manfiy harakatlar bilan, narxlar qaytarilmaydi; raqam tenant qulfi bilan), `InventoryCount`(+Item: post paytida expected keshdan, farq `inventory` harakati, sanalmagan tovar o'zgarmaydi). API: `/suppliers/`, `/stock-receipts/` (+post, +reverse), `/inventory-counts/` (+post), `/stock/` (low/negative), `/stock-movements/`. `TenantPKField` → `apps/core/serializers.py`. 376 test yashil (+52).
- PR: T-015 (squash merge)
- Qoldi / keyingi qadam: T-016 Mijozlar va nasiya. `low` filtri faqat harakati bor tovarlar — to'liq "kam qolganlar" T-054 da.
- Muammo yoki qaror: elektr uzilishi `.git/config` ni nol baytlar bilan buzdi — foydalanuvchi tikladi. ViewSet'da action metodini `post` deb nomlash DRF'da detail URL'ga POST'ni shu action'ga yo'naltiradi — `post_document` + `url_path="post"` ishlatildi (405 testi bor).

## 2026-10-14 — T-016 Mijozlar va nasiya
- Qilindi: `apps/customers` — `Customer` (ism, telefon unique emas, `debt_limit_tiyin`: null = cheklovsiz, 0 = nasiya yo'q; yumshoq o'chirish, qarzi bo'lsa `409 customer_has_debt`), `DebtEntry` (AppendOnlyModel; turlar sale/payment/refund/adjustment, DB constraint'lar: ishora turga mos, `method` faqat to'lovda, `sale_id` savdo/qaytarishda). Balans = yig'indi (annotatsiya, kesh yo'q). Servislar: `check_debt_limit`, `record_sale_debt`/`record_refund_debt` (T-017 uchun), `pay_debt` (mijoz qulfi; `enforce_balance=False` — sinxron uchun), `adjust_debt`. API: `/customers/` (balans, qidiruv, `has_debt`, qarzdorlar birinchi), `/{id}/debt-entries/`, `/{id}/payments/` (har bir xodim), `/{id}/adjustments/` (faqat ega). Limitni faqat ega/menejer o'rnatadi. `ClientIdMixin` → `apps/core/serializers.py`. Spec `customers-api.md`. 425 test yashil (+49).
- PR: T-016 (squash merge)
- Qoldi / keyingi qadam: T-017 Savdo, smena, qaytarish (qarzga savdo `record_sale_debt` ni chaqiradi; naqd qarz to'lovini smenaga bog'lash — T-017).
- Muammo yoki qaror: Q-003 — qarzdan ko'p to'lov vaqtincha rad etiladi (A), javob kutilmoqda. Limitdan oshgan qarzga savdo serverda rad etilmaydi (kassada menejer ruxsati).

## 2026-10-14 — T-017 Savdo, smena, qaytarish
- Qilindi: `apps/sales` — `Shift` (qurilmada bitta ochiq — DB constraint; yopishda `expected_cash` saqlanadi), `Sale` (o'zgarmas, faqat `status` qaytarishda), `SaleItem`, `SalePayment`, `Refund`, `RefundItem`, `CashMovement` (AppendOnly; summalar DB constraint bilan). Servislar (`apps/sales/services/`, T-018 sinxron chaqiradi): `open_shift`, `close_shift`, `record_cash_movement`, `shift_report` (X/Z), `record_sale` (qator/summa/to'lov tekshiruvi, `StockMovement(sale, −)`, nasiya → `DebtEntry`), `record_refund` (qoldiq miqdor, proporsional summa, oxirgi qismda yaxlitlash qoldig'i, chek chegirmasi ulushi, nasiyadan ayirish cheklovi, `StockMovement(refund, +)`, `Sale.status`). Bog'liq obyekt yo'q → `MissingDependency` (sinxronda `pending`). `DebtEntry.shift` (naqd qarz to'lovi kutilgan naqdga kiradi). REST faqat o'qish: `/shifts/` (+`report`), `/sales/` (sana filtri do'kon vaqt zonasida), `/refunds/`, `/cash-movements/`; kassir faqat o'zinikini ko'radi. `ENUM_NAME_OVERRIDES` (method/status). Spec `sales-api.md` (sinxron payload shartnomasi). 505 test yashil (+80).
- PR: T-017 (squash merge)
- Qoldi / keyingi qadam: T-018 Sinxronlash API (`sync/push` hodisalarni shu servislarga yo'naltiradi, `MissingDependency` → pending; `sync/pull` ChangeLog).
- Muammo yoki qaror: limitdan oshgan nasiya va manfiy qoldiq savdoni rad etmaydi (oflayn-birinchi). Qaytarish tasdig'i kassada; server `approved_by` ega/menejer ekanini tekshiradi, lekin talab qilmaydi.
