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

## 2026-10-14 — T-018 Sinxronlash API
- Qilindi: `apps/sync` — `SyncEvent` (klient UUID, applied/pending/rejected, urinishlar), `ChangeLog` (`seq` + `txid`). `POST /api/v1/sync/push/` (qurilma tokeni; idempotent; qurilma qatori qulflanadi; har hodisa savepoint'da; `created_at` tartibi; `pending` — bog'liq obyekt yo'q yoki kutilmagan xato, har push'da qayta urinish, 7 kundan keyin `rejected`; `id_conflict`, `unknown_event`). `handlers.py` — 11 hodisa turi: smena/pul/savdo/qaytarish (T-017 servislari), `debt.paid`, `customer/supplier/product.upserted` (REST serializer + `by` huquqlari), `receipt/inventory.posted`. `GET /api/v1/sync/pull/` — ChangeLog'dan entitylar (unit, category, product+barcodes, supplier, customer+balans, user+pin_hash, store, debt_entry, stock), sahifa ichida dedupe, `delete` op, obuna holati, server vaqti. Signal'lar + `update()`/`bulk_create` joylari uchun aniq yozuv; mavjud ma'lumot uchun backfill migratsiya. `subscription_snapshot` billing'ga chiqarildi. Spec `sync-api.md`, `sync.md` yangilandi. 552 test yashil (+47).
- PR: T-018 (squash merge)
- Qoldi / keyingi qadam: T-019 Do'kon egasi hisobotlari API. Kassa tomoni (outbox, pull dvigateli) — T-035.
- Muammo yoki qaror: **teshiksiz pull kursori** — `seq` commit'dan oldin ajratilgani uchun kichik `seq` li tranzaksiya keyin commit bo'lsa oddiy `seq > cursor` uni o'tkazib yuborardi. Yechim: yozuvda `txid` (`pg_current_xact_id`), pull faqat `txid < pg_snapshot_xmin` yozuvlarni `(txid, seq)` tartibida beradi; kursor — satr `"<txid>:<seq>"`. Standart birliklar (`bulk_create`) va kategoriya o'chirish (`update()`) ChangeLog'ga tushmayotgani testda topilib tuzatildi.

## 2026-10-14 — T-019 Do'kon egasi hisobotlari API
- Qilindi: `apps/reports` (modelsiz) — `GET /api/v1/reports/summary|by-day|by-hour|top-products|cashiers|debts|stock/` (ega va menejer). Davr do'kon vaqt zonasida (`date_from`/`date_to`, standart bugun, ≤ 366 kun), oldingi teng davr bilan solishtirish (bazis punkt). Tushum = savdolar − qaytarishlar (qaytarish o'z kunida); foyda = tushum − sotilgan tannarx + qaytarilgan tannarx; qator tannarxi SQL `ROUND(numeric)` (musbatda half-up, `line_total` bilan bir xil). Top tovarlar (tushum/miqdor/foyda, asc/desc), kassirlar, qarzdorlar (joriy), ombor qiymati, kam qolgan (qoldiq qatori bo'lmasa ham) va manfiy qoldiq. Spec `reports-api.md`. 573 test yashil (+21), barcha raqamlar qo'lda hisoblangan qiymatlar bilan (vaqt zonasi chegarasi, chek chegirmasi, vaznli tovar yaxlitlashi, qaytarish).
- PR: T-019 (squash merge)
- Qoldi / keyingi qadam: T-020 Platforma admin API. xlsx eksport — klientda (kassa/admin).
- Muammo yoki qaror: Q-004 — foyda chek chegirmasi va qaytarishlar bilan (A, vaqtincha); `data-model.md` dagi qator formulasi ularni hisobga olmasdi.

## 2026-10-14 — T-020 Platforma admin API
- Qilindi: `apps/platform_admin` — `AdminAuditLog` (o'zgarmas; actor, action, target, tenant, before/after — sirlarsiz, sabab). `/api/v1/platform/...` (faqat platform_admin): tenantlar (ro'yxat — jonli obuna holati, qidiruv, holat filtri, qurilmalar soni, oxirgi faollik; karta; onboarding — tenant + do'kon + birliklar + ega + sinov obunasi bitta tranzaksiyada, vaqtinchalik parol faqat javobda; tahrir; bloklash/ochish sabab bilan; obuna sozlamalari; xodimlar; parol tiklash; sinxron hodisalari), tariflar CRUD (DELETE = nofaol), to'lovlar (kiritish, bekor qilish, ro'yxat + filtrlangan jami), qurilmalar (filtrlar, bloklash), statistika (holatlar, MRR, shu oy tushum, 7 kunda tugaydiganlar, sinxronlanmagan qurilmalar, 12 oylik tushum), audit jurnali. Har o'zgarish audit bilan bitta tranzaksiyada. Spec `platform-api.md`. 704 test yashil (+131: 23 endpoint × 3 rol = 403, anonim = 401).
- PR: T-020 (squash merge)
- Qoldi / keyingi qadam: 1-bosqich (backend yadrosi) tugadi. Keyingi: 2-bosqich — T-030 Dizayn tizimi (packages/ui, Flutter).
- Muammo yoki qaror: testlar ikkita xatoni topdi — onboarding audit yozuvida `tenant` bo'sh edi; band telefon 500 berardi (model validatsiyasi) → oldindan tekshiruv, `409 phone_taken`.

## 2026-10-14 — T-030 Dizayn tizimi (packages/ui)
- Qilindi: tokenlar — `PosPalette` (ThemeExtension, semantik ranglar + 2 daraja soya), `PosTone`, `PosTypography` (Inter 4.1 paketga qo'shildi, tabular raqamlar), `PosSpacing/Radius/Sizes/Motion`, `PosWindowSize`; to'liq `PosTheme` (Material komponentlari ham); `PosFormat` (summa NBSP bilan, miqdor). 20 komponent: Button(+Keycap), IconButton, TextField, SearchField, NumericKeypad, MoneyText, QtyStepper, Card, ListTile, Badge, StatusDot, Dialog/Sheet, Toast(undo), EmptyState, Skeleton, DataTable, ResponsiveScaffold, StatusBar, PinPad, ScanFeedback. Widgetbook: 9 galereya + dialog, knob playground. Spec'ga "Amalga oshirilishi" bo'limi.
- Testlar: ui 131 (kontrast AA har juftlik × 2 mavzu, breakpoint, formatlash, har komponent xatti-harakati: klaviatura, Esc, 5 s toast, fizik PIN klaviatura, tor jadval), widgetbook 62 (60 golden: 10 sahifa × 3 o'lcham × 2 mavzu). Skrinshotlar `docs/screenshots/T-030/`.
- PR: T-030 (squash merge)
- Qoldi / keyingi qadam: T-031 Tarjimalar va formatlash (`PosFormat` dan foydalanish mumkin). T-033 karkas uchun `PosResponsiveScaffold` tayyor.
- Muammo yoki qaror: spec ranglari WCAG AA dan o'tmadi (oq matn success/warning ustida 3,3/3,2; qorong'i primary 3,7) → tuzatildi, spec'da yozildi. Golden'lar widgetbook paketida (galereyalar bilan bitta manba), `make ui-test` ikkalasini ishga tushiradi. flutter_test standartda soyalarni qattiq chizadi — golden testda `debugDisableShadows=false` (test ichida, oxirida qaytariladi). Tor ekranda jadval sarlavhasi toshib ketardi → ustun `minWidth` + gorizontal surish.

## 2026-10-14 — T-031 Tarjimalar va formatlash
- Qilindi: ARB (uz shablon har kalitda izoh bilan, uz_Cyrl, ru): valyuta, birliklar (pcs/kg/g/l/m/pack), navigatsiya bo'limlari, umumiy amallar, holat qatori (ICU ko'plik; rus `one/few/many`). `AppFormat` (`context.fmt`): summa `125 000 so'm`/`сўм`/`сум`, miqdor birlik bilan (`1,250 kg`, `3 шт`), sana `13.10.2026`, vaqt `20:15` do'kon zonasida. `UnitCode`, `StoreTimeZone` (qaror 0007 — UTC+5 qat'iy, IANA bazasisiz). Til tanlovi lokal bazada saqlanadi va `main` da oldindan o'qiladi; `LanguagePicker`. Kassa ekrani `PosEmptyState` ga o'tdi (qattiq o'lchamlar olib tashlandi).
- Testlar: apps/pos 31 (+26): formatlash 3 tilda, kun chegarasi (19:00 UTC = 00:00 Toshkent), qurilma zonasidan mustaqillik, ko'plik shakllari; ARB kalitlari/placeholder/izohlar mosligi; `lib/` da qattiq yozilgan matn yo'qligi (Text va label/title/hint/tooltip/... parametrlari; `// i18n-ignore` istisno); til saqlash/tiklash, buzilgan qiymat, `LanguagePicker`.
- PR: T-031 (squash merge)
- Qoldi / keyingi qadam: T-032 Lokal baza (Drift). Do'kon vaqt zonasi hozircha Toshkent — sinxron (T-034/T-035) `Store`/`Tenant.timezone` ni olib kelgach `context.fmt` ga ulanadi.
- Muammo yoki qaror: 0007 — kassada IANA bazasi o'rniga qat'iy UTC+5.

## 2026-10-14 — T-032 Lokal baza (Drift)
- Qilindi: 27 jadval (ma'lumotnomalar, hujjatlar, outbox/sync_state/cart_drafts/doc_counters), sxema v2 + `make-migrations` (surat `drift_schemas/`, `stepByStep` from1To2, generatsiya qilingan migratsiya testlari), WAL + `synchronous=FULL` + `foreign_keys`. `Money` (server `money.py` nusxasi, umumiy vektorlar), `SaleWriter` (savdo bitta tranzaksiyada + outbox `sale.completed`, server payload formati, chek raqami), `OutboxWriter` (navbat, kutayotganlar soni stream'i), UUIDv7 (`uuid`).
- Testlar: apps/pos 52 (+21): migratsiya v1→v2 (sxema mosligi + til sozlamasi saqlanadi), fayl bazada pragmalar va qayta ochishda saqlanish, bitta ochiq smena, FK, unique chek raqami, 64-bit butun son; savdo: naqd/karta/nasiya, payload, ketma-ket raqam, server qoidalari bo'yicha validatsiya, **atomarlik** (tranzaksiya o'rtasida xato → hech narsa yozilmaydi, raqam band bo'lmaydi), noma'lum smena → FK rad etadi.
- PR: T-032 (squash merge)
- Qoldi / keyingi qadam: T-033 Ilova qobig'i va navigatsiya. Pull/push (T-035) va qoldiq hisobi (server + yuborilmagan harakatlar) — keyin.
- Muammo yoki qaror: build_runner keshi ko'chirilgan `pos_colors.dart` tufayli yiqildi va eski `.g.dart` qoldi → `rm -rf apps/pos/.dart_tool/build`. CI filtriga `testdata/**` qo'shildi (pul vektorlari ikkala tomonda ishlatiladi).

## 2026-10-14 — T-033 Ilova qobig'i va navigatsiya
- Qilindi: go_router `StatefulShellRoute.indexedStack` — 6 bo'lim (`/pos`, `/products`, `/receiving`, `/customers`, `/reports`, `/settings`), ochilganda kassa, bo'lim holati saqlanadi. `AppShell` (`PosResponsiveScaffold`: telefon — pastki panel, planshet/desktop — yon panel), desktop tezkor tugmalari **Ctrl+1…6** (F-tugmalar kassa ekraniga band). `AppStatusBar`: internet, navbatdagi yozuvlar (outbox'dan jonli), printer, smena (bazadan jonli), soat (do'kon vaqti). Sozlamalar — til tanlash; qolgan bo'limlar "tayyorlanmoqda". `PosResponsiveScaffold` telefonda o'z pastki paneliga o'tdi (6 bo'limda yorliq bir qatorda).
- Testlar: apps/pos 74 (+22): navigatsiya (bosish, Ctrl+N, bo'lim ichida Tab/Enter), joylashuv 3 o'lchamda, til almashtirish, holat qatori (standart, oflayn+navbat, bazadagi smena/outbox o'zgarishi); 12 golden (kassa va sozlamalar × 3 o'lcham × 2 mavzu). Skrinshotlar `docs/screenshots/T-033/`.
- PR: T-033 (squash merge)
- Qoldi / keyingi qadam: T-034 Kirish, qurilmani ulash, PIN ekrani. Internet/printer holati — T-035/T-044 da haqiqiy manbaga ulanadi (`connectionStatusProvider`, `printerStatusProvider`).
- Muammo yoki qaror: go_router bo'lim navigatorlari fokus doirasi `closedLoop` — Tab bo'lim ichida aylanadi, yon panelga chiqmaydi (global `requestFocus: false` dialoglar fokusini buzadi). Shuning uchun bo'limlararo klaviatura — Ctrl+1…6. Telefonda `NavigationBar` "Sozlamalar" ni ikki qatorga bo'lardi → o'z paneli. Testda `runAsync` + drift stream osilib qoldi → bazaga yozish to'g'ridan-to'g'ri test tanasida.

## 2026-10-14 — T-034 Kirish, qurilmani ulash, PIN ekrani
- Qilindi: Dart API klient generatsiyasi sozlandi (`packages/api_client_dart`: swagger_parser + retrofit + json_serializable; auth, devices, sync). API faqat JSON (`DEFAULT_PARSER_CLASSES`) — generator multipart tanlamasin; `openapi.yaml` va admin `schema.d.ts` yangilandi. Kassada: `DeviceRegistration` (login → register, qayta urinishda o'sha ID, token `flutter_secure_storage` da), `PullApplier`/`SyncPuller` (barcha pull entity'lari, sahifa bitta tranzaksiyada, kursor/obuna/`offline_grace_until`/soat farqi), `PinHash` (PBKDF2, server vektorlari), `PinGate` (5 xato → 60 s, bazada), `Session` (setup → initialSync → locked → unlocked) va router redirect, `SetupScreen` (3 qadam + sinxron progress + qayta urinish), `LockScreen` (xodim tanlash + PinPad, fizik klaviatura, Esc), `AutoLock` (sozlanadigan), qobiqda xodim va qulf tugmasi. `PosPinPad`/`PosNumericKeypad` — ✓ tasdiqlash tugmasi (4–6 raqamli PIN).
- Testlar: apps/pos 130 (+56): ro'yxatdan o'tish (xatolar, qayta urinish), pull (har entity, server g'olib, shtrix-kod ko'chishi, soft/hard delete, noma'lum entity, atomarlik, sahifalash, tarmoq uzilishi), PIN (RFC vektori, server vektorlari, noto'g'ri/buzilgan xesh, isolate), kirish oqimi end-to-end soxta server bilan, PIN 5 xato → kutish → tugashi, avtomatik qulflash, loadSession; 18 auth golden + 12 shell golden yangilandi. ui 133 (+2).
- PR: T-034 (squash merge)
- Qoldi / keyingi qadam: T-035 Sinxronlash dvigateli — push (outbox), fon tsikli (10 s / 60 s), ulanish kuzatuvi, eksponensial kutish, `readonly` rejim. Pull qismi shu vazifada qilindi (birinchi sinxron uchun kerak edi).
- Muammo yoki qaror: swagger_parser bir nechta content-type bo'lsa multipart'ni tanlaydi → server JSON-only. PIN uzunligi xeshdan noma'lum → ✓/Enter bilan tasdiqlash. Widget testlarda PIN tekshiruvi soxta (`PinGate(verify:)`), haqiqiy PBKDF2 — unit testda.

## 2026-10-14 — T-035 Sinxronlash dvigateli
- Qilindi: `OutboxPusher` (tartib, 100 tadan, natijalar, eksponensial kutish 5 s → 5 daq, navbat boshi kutsa — hech narsa), `SyncEngine.syncOnce` (push → pull, `SyncHealth`: online/offline/unauthorized/deviceBlocked), `SyncRunner` (10 s push, yangi hodisada 1 s, 60 s pull; ulanmagan qurilmada ishlamaydi), ulanish holati sinxrondan, `salesBlockProvider` (readonly/blocked/oflayn muddati — server soati bilan tuzatilgan/qurilma bloklangan), soat farqi va rad etilgan yozuvlar — holat qatorida. Vaqt manbai `package:clock` (testlarda soxta vaqt).
- Testlar: apps/pos 152 (+22): push tartibi va natijalari, 100 lik paketlar, kutish o'sishi va tartib saqlanishi; **sync.md mezonlari**: 5 — 500 oflayn savdo → serverda aynan 500; 6 — javob yo'qolganda qayta yuborishda dublikat yo'q; 8 — readonly'da savdo o'chiq, sinxron ishlaydi; qurilma bloki, 401, tokensiz; oflayn muddati (chegara ±1 daq), orqada qolgan qurilma soati, bloklangan tenant; fon tsikli widget testlari (birinchi sikl, yangi hodisa, 10 s/60 s, oflayn → qayta tiklanish, PIN ekranida ham, ulanmaguncha yo'q).
- PR: T-035 (squash merge)
- Qoldi / keyingi qadam: 3-bosqich — T-040 Skaner xizmati. Savdo tugmasi `salesAllowedProvider` ga ulanadi (T-042/T-043).
- Muammo yoki qaror: kutish butun navbatga (eng eski hodisa bo'yicha) — tartib buzilmasin. Widget testlarida `DateTime.now()` soxta vaqtni bilmaydi → `clock.now()`.

## 2026-10-14 — T-040 Skaner xizmati
- Qilindi: `Barcodes` (server bilan bir xil format va GTIN nazorat raqami), `WeightedBarcodeFormat` (tarozi EAN-13: prefiks 20–29, PLU 5, vazn/narx, kasr), `BarcodeScannerService` (HID skanerni fokusdan qat'i nazar ajratish: bufer + 35 ms + ≥ 4 belgi + Enter/Tab; inson yozuvi fokusdagi maydonga qaytariladi yoki `onTyping`; ro'yxatdan o'tgan ekran bo'lmasa aralashmaydi), `ScanListener` (ko'rinadigan va eng yuqori ekran), kamera skaneri (`mobile_scanner`, Android/iOS; iOS/Android kamera ruxsati), `ScanSignal` (ovoz/vibratsiya), Sozlamalarda skaner kartasi (ovoz, tezlik).
- Testlar: apps/pos 177 (+25): barcode.md test ro'yxati (13 belgi 10 ms → bitta hodisa va maydon bo'sh; 150 ms → oddiy matn; `2012345012509` → PLU 12345, 1,250 kg; noto'g'ri nazorat raqami), qisqa kod, Tab, inson yozuvi orasida skaner, `onTyping`, ro'yxatsiz klaviatura tegilmaydi, Ctrl tezkor tugmalar, stack/ko'rinmas ekran, kamera yo'li; skaner sozlamalari saqlanishi va qo'llanishi.
- PR: T-040 (squash merge)
- Qoldi / keyingi qadam: T-041 Smena ochish/yopish. Kassa ekrani (T-042) `ScanListener` + `onTyping` → qidiruv, `PosScanFeedback` + `ScanSignal`.
- Muammo yoki qaror: tugmani "ushlab, keyin qaytarish" — chunki framework qayta ishlagan klaviatura hodisasi platformaning matn kiritishiga yetib bormaydi; qaytarish `EditableTextState.userUpdateTextEditingValue` orqali (formatter va onChanged ishlaydi). Haqiqiy qurilmada (Windows HID skaner) qo'lda sinash — T-090 chidamlilik testlarida.

## 2026-10-14 — T-041 Smena ochish/yopish
- Qilindi: `ShiftService` (ochish — oldingi sanalgan naqd taklif qilinadi, yopish — sanalgan naqd va farq, X/Z hisobot: savdolar, to'lov turlari, qaytarishlar, kiritish/chiqarish, qarz to'lovlari, kutilgan naqd; outbox `shift.opened`/`shift.closed`), kassa ekrani smena yopiq bo'lsa "Smenani oching" kartasi (savdo yo'q), `/pos/shift` — X hisobot, yopish oynasi (farq darhol: ortiqcha/kam), Z hisobot. `MoneyInput` (katta summa + ekran klaviaturasi `00`, fizik klaviatura). Holat qatoridagi smena belgisi — shu qurilma smenasi.
- Testlar: apps/pos 211 (+34): ShiftService unit testlari (Z raqamlari savdolar bilan mos), widget testlari (ochish, taklif, X hisobot, yopish → kam, bekor qilish), golden'lar (ochish, X, yopish, Z × 3 o'lcham × 2 mavzu). Skrinshotlar `docs/screenshots/T-041/`, qobiq — `T-033/` yangilandi.
- PR: T-041 (squash merge)
- Qoldi / keyingi qadam: T-042 Kassa ekrani — savat. Z hisobot chekini chop etish — T-044 (tugma hozircha o'chiq); pul kiritish/chiqarish UI — T-046.
- Muammo yoki qaror: uzilishdan tiklandi — UI qadami commit qilinmagan edi, analyze xatolari tuzatildi. `MoneyInput` bir kadr ichida kelgan bir nechta tugmada raqam yo'qotardi (qiymat faqat ota qayta chizganda yangilanardi) — ichki holat bilan tuzatildi.

## 2026-10-14 — T-042 Kassa ekrani — savat
- Qilindi: katalog indeksi xotirada (`ProductCatalog`: shtrix-kod, tarozi kodi → PLU, qidiruv nom/shtrix-kod boshi/PLU, lotin/kirill farqsiz `SearchKey`), savat (`CartController`: +1/vaznli yangi qator, miqdor, o'chirish + undo, qator/chek chegirmasi, 5 ta kechiktirilgan chek, `cart_drafts` ga avto-saqlash — baza v3 `discount_json`), chegirma huquqi (kassir 5% gacha, undan katta — menejer/ega PIN, `approvedBy`), kassa ekrani (desktop/planshet ikki panel, telefon bir ustun + tez tugmalar varag'i + yopishqoq JAMI/To'lash, chapga surib o'chirish), miqdor va chegirma oynalari, F1/F2/F3/F6/F12/Delete/↑↓/Enter/Esc, skaner (topilmadi, nofaol, nazorat raqami xato), savdo to'xtaganda banner.
- Testlar: apps/pos 278 (+67): SearchKey, katalog (10 000 tovarda < 50 ms), savat va avto-saqlash/tiklash, v2→v3 migratsiya, chegirma siyosati, kassa ekrani widget testlari (skaner, qidiruv, tez tugmalar, klaviatura, undo, chegirma + PIN, ilova qayta ochilganda savat, telefon surish), golden'lar (savat/qidiruv/bo'sh × 3 o'lcham × 2 mavzu); packages/ui 134 (+1). Skrinshotlar `docs/screenshots/T-042/`.
- PR: T-042 (squash merge)
- Qoldi / keyingi qadam: T-043 To'lov oynasi (F12 hozircha xabar). F4 mijoz — T-043; narxni o'zgartirish (menejer PIN) va "Bu kod bazada yo'q → Tovar qo'shish" tez formasi — tovar kartasi bilan keyin; chegirma chegarasini o'zgartirish ekrani — ega sozlamalari. Q-005 javobi kutilmoqda.
- Muammo yoki qaror: `PosScanFeedback` dispose paytida ticker yaratardi (tuzatildi + test). Oyna ochiq paytda skaner xizmati raqamlarni yutardi → `ScanListener.enabled`. Desktopda fokus olgan qidiruv maydoni matnni belgilaydi → kursor oxirga qo'yiladi. Widget testi teardown'ida drift yozuvini kutish testni osiltiradi.

## 2026-10-15 — T-043 To'lov oynasi
- Qilindi: to'lov modeli (`PaymentDraft`: naqd/karta/nasiya/aralash, qaytim, xatolar), `Checkout` — savat + to'lov bitta SQLite tranzaksiyasida (savdo, qatorlar, to'lovlar, qoldiq, qarz, outbox), mijozlar ro'yxati (`CustomerDirectory`: qidiruv, balans = qarz daftari, tez yaratish + `customer.upserted`, limit), to'lov oynasi (tez summalar Aniq/50 000/100 000/200 000, klaviatura, katta yashil qaytim, karta, nasiya + limitdan oshsa menejer PIN, aralash; oyna ochiqda skan → "Avval to'lovni yakunlang"), F12 → yakunlash → savat bo'shaydi, 3 s "Savdo yakunlandi · Qaytim …"; F4 chek mijozi, savat ostida mijoz qatori.
- Testlar: apps/pos 317 (+39): PaymentDraft, CustomerDirectory, Checkout atomarligi, 12 widget testi (3 harakat: skan → F12 → Enter; qaytim; karta; nasiya + limit + PIN; yangi mijoz; aralash; skaner bloklangan; F4; telefon), golden'lar `pay_cash`/`pay_debt` × 3 o'lcham × 2 mavzu. Skrinshotlar `docs/screenshots/T-043/`, qobiq — `T-033/` yangilandi.
- PR: T-043 (squash merge)
- Qoldi / keyingi qadam: T-044 Chek chop etish (yakunlashda chek, "Chek chiqmadi, qayta chop etish"). Telefonda F4 tugmasi yo'q — mijozni nasiya tabidan tanlash mumkin.
- Muammo yoki qaror: Flutter'da `HardwareKeyboard` ishlovchisi `true` qaytarsa ham hodisa `Focus.onKeyEvent` ga yetadi — to'lov oynasida raqamlar faqat skaner xizmatining `onTyping` i orqali (`MoneyInput(hardwareDigits: false)`), skaner Enter'i yutiladi. Telefonda naqdda ekran klaviaturasi yopiq — aks holda qaytim va "Yakunlash" ekrandan chiqib ketadi.

## 2026-10-15 — T-044 Chek chop etish
- Qilindi: chek matni generatori (`ReceiptBuilder`: 58/80 mm, nom o'rash, qator/chek chegirmasi, to'lovlar, qaytim, nasiya mijozi va qarzi, "NUSXA", ilova tilida) va `ReceiptLoader` (bazadan). ESC/POS kodlovchi (CP866 + o'zbek kirill → rus harflari, UTF-8, qalin, markaz, kesish, pul qutisi). Ulanish: tarmoq IP:9100 va Windows spooler (o'z FFI bog'lamalari, RAW). Printer sozlamalari (`local_settings`) va Sozlamalar → Chek printeri sahifasi (test chek, pul qutisi). Kassada chek fonda chiqadi, xato bo'lsa "Chek chiqmadi" va "Qayta chop etish"; "Oxirgi chek" tugmasi; holat qatorida haqiqiy printer holati.
- Testlar: apps/pos 353 (+36): chek snapshotlari (`test/printing/receipts/*.txt`), ESC/POS baytlari, `ReceiptLoader`, `PrinterService` (nusxa, pul qutisi, qayta chop etish, xato), tarmoq printeri (lokal `ServerSocket`), Windows spooler (`EnumPrinters`, noma'lum printer), 6 widget testi (avtomatik chek, printer o'chiq → savdo bor + qayta chop etish, autoPrint o'chiq + "Oxirgi chek", printersiz, sozlamalar). Golden'lar: sozlamalar × 3 o'lcham × 2 mavzu. Skrinshotlar va chek namunalari: `docs/screenshots/T-044/`.
- PR: T-044 (squash merge)
- Qoldi / keyingi qadam: T-045 Qaytarish. Android Bluetooth/USB printer — T-047 (qaror 0008). Z hisobot chekini chop etish — `ReceiptBuilder` asosida keyin.
- Muammo yoki qaror: qaror 0008 — tarmoq + Windows spooler, Bluetooth/USB keyinroq. `win32` 6.x o'rniga winspool'ning 8 funksiyasi o'zimiz bog'landi. Chek xatosi "Savdo yakunlandi · Qaytim" xabarini yopmasligi uchun ular bitta xabarga qo'shildi.

## 2026-10-15 — T-045 Qaytarish
- Qilindi: qaytarish hisobi (`RefundQuote`) server `record_refund` bilan aynan bir xil: qator ulushi, oxirgi qismda yaxlitlash qoldig'i yopiladi, chek chegirmasidan ulush, to'liq yopishda qoldiq, qarzdan ayirish chegarasi. `SaleLookup`: raqam, oxirgi cheklar, qaytarilgan miqdorlar. `RefundWriter` bitta tranzaksiyada yozadi: Refund, qatorlar, qoldiq +, qarz −, `sales.status`, outbox `refund.created`. Chekda savdo raqamining CODE128 shtrix-kodi. Qaytarish oynasi (F8 / ikon): topish (raqam, skan, ro'yxat), qisman yoki to'liq, sabab, naqd yoki qarzdan ayirish, menejer/ega PIN; menejer o'zi bo'lsa PIN qayta so'ralmaydi. Telefonda "Yangi chek" endi ikon.
- Testlar: apps/pos 384 (+31): server vektorlari bilan hisob testlari, writer (qisman → to'liq, nasiya, atomarlik, qidiruv), CODE128 baytlari, 7 ta widget testi (ro'yxatdan qisman + PIN, raqam bo'yicha to'liq, skan, tekshiruvlar, nasiya, menejer, telefon). Golden'lar: `refund` find/items × 3 o'lcham × 2 mavzu. Kassa va qobiq golden'lari yangilandi. Skrinshotlar: `docs/screenshots/T-045/`.
- PR: T-045 (squash merge)
- Qoldi / keyingi qadam: T-046 Kassaga pul kiritish/chiqarish. Boshqa kassada sotilgan chekni qaytarish — Q-006 (hozircha faqat shu kassa savdolari). Qaytarish chekini chop etish — keyin.
- Muammo yoki qaror: tarjima testi qattiq yozilgan namuna (`D1-000001`) va tooltip'dagi `(F8)` ni ushladi — tarjimaga o'tkazildi. Skaner bilan chek raqamini o'qish uchun test yordamchisiga `-` qo'shildi.

## 2026-10-15 — T-046 Kassaga pul kiritish/chiqarish
- Qilindi: `ShiftService.moveCash` — `cash_movements` va outbox `cash.moved` bitta tranzaksiyada; faqat ochiq smenaga; chiqarish kutilgan naqddan oshmaydi. Kassa puli oynasi (F9 kassada, smena sahifasida tugmalar): turi, summa, sabab (tez tugmalar va matn, majburiy), kassadagi naqd ko'rinadi. Smena sahifasida harakatlar ro'yxati. X/Z hisobot cheki (`ReceiptBuilder.buildShift`, `PrinterService.printShiftReport`), smena sahifasida "Chek chiqarish" (T-044 da o'chiq qolgan edi).
- Testlar: apps/pos 405 (+21): `moveCash` (outbox payload, Z da naqd balansi to'g'ri, ortiqcha chiqarish rad etiladi, yopiq smena), X/Z chek snapshotlari, 4 ta widget testi (F9 kiritish, rad etish, smena sahifasi + ro'yxat + X hisobot, X chekini chop etish). Golden'lar: `shift` cash_out / cash_list, X/Z kassa puli bilan. Skrinshotlar: `docs/screenshots/T-046/`.
- PR: T-046 (squash merge)
- Qoldi / keyingi qadam: 3-bosqich (kassa) yopildi; keyingisi — 4-bosqich, T-050 Tovarlar ro'yxati va kartasi.
- Muammo yoki qaror: chiqarish kutilgan naqddan oshmasligi kassa tomonidagi qoida (server rad etmaydi). Haqiqiy naqd kutilgandan ko'p bo'lsa, ortiqchani avval "kiritish" orqali qayd qilish kerak. "Pul kiritish/chiqarish" tugmalari desktop'da bir qatorga sig'magani uchun harakatlar kartasiga ko'chirildi.

## 2026-10-15 — T-050 Tovarlar ro'yxati va kartasi
- Qilindi:
  - Backend: narx tarixi — `GET /api/v1/products/{id}/price-history/` (JWT, ega/menejer) va kassa uchun `GET /api/v1/sync/price-history/?product=` (qurilma tokeni); OpenAPI, admin TS va Dart klientlari qayta yaratildi.
  - Kassa: `ProductEditor` — server qoidalari bilan tekshiradi; lokal baza + outbox `product.upserted` bitta tranzaksiyada, `by` — menejer/ega.
  - Lokal qoldiq: server qiymati + yuborilmagan harakatlar.
  - "Tovarlar" bo'limi: qidiruv, kategoriya va holat filtrlari, jadval/kartalar; skaner → karta yoki yangi karta.
  - Tovar kartasi: barcha maydonlar, ustama %, shtrix-kodlar skaner bilan, narx tarixi (onlayn).
- Testlar:
  - backend: +9 (narx tarixi: tartib, muallif, kassir 403, boshqa tenant 404, qurilma endpoint'i);
  - apps/pos: 437 (+32): `ProductEditor` va qoldiq, 13 ta widget testi, parse yordamchilari.
  - Golden'lar: `products` list/card × 3 o'lcham × 2 mavzu. Skrinshotlar: `docs/screenshots/T-050/`.
- PR: T-050 (squash merge)
- Qoldi / keyingi qadam: T-051 Excel/CSV import. T-047 — Q-007 (Android qurilma kerak). Kategoriya va birliklarni kassada boshqarish — keyin (hozir pull'dan).
- Muammo yoki qaror:
  - Kassada xodim JWT'si yo'q, faqat qurilma tokeni bor. Shuning uchun narx tarixi uchun sync nomlar maydonida qurilma endpoint'i qo'shildi; kim ko'rishi kassada lokal rol bilan cheklanadi (product.upserted `by` bilan bir xil ishonch modeli).
  - Testlar ikki xatoni ushladi: kasrsiz birlikda `parseQtyMilli` regex guruhi xatosi va planshetda jadvaldagi qoldiq ustunining sig'masligi.

## 2026-10-15 — T-051 Excel/CSV import
- Qilindi:
  - Spec `product-import.md` va qaror 0009 — import serverda bajariladi.
  - Backend (`apps/catalog/importing.py`):
    - o'qish: xlsx (`openpyxl`) va CSV (UTF-8/CP1251, `,`/`;`/tab);
    - ustunlarni sarlavhadan taklif qilish (uz/ru sinonimlar);
    - qator tahlili: pul → tiyin, birlik sinonimlari, shtrix-kod qoidalari, fayldagi takror;
    - qo'llash bitta tranzaksiyada, bulk: yangi kategoriyalar, yangi va shtrix-kod bo'yicha yangilangan tovarlar, narx tarixi, yangi tovarlarning boshlang'ich qoldig'i — bitta tasdiqlangan kirim;
    - bulk signal bermagani uchun `ChangeLog` qo'lda yoziladi.
  - API (qurilma tokeni): template / upload / check / apply; `ProductImport` 24 soat saqlanadi.
  - Kassa: "Excel'dan yuklash" oynasi (fayl → ustunlarni moslash → tekshirish → import → natija), shablonni saqlash, kassir uchun menejer PIN, importdan keyin darhol pull; oflaynda "internet kerak".
- Testlar:
  - backend +12: 5000 qator (30 s chegarasi), xatolar, CSV cp1251, qurilma/tenant izolyatsiyasi, muddat tugashi, takroriy apply 409, kassir `by` 400;
  - apps/pos 454 (+17): 5 ta import widget testi; golden'lar `products/import_map`, `import_check` × 3 o'lcham × 2 mavzu.
  - Skrinshotlar: `docs/screenshots/T-051/`.
- PR: T-051 (squash merge)
- Qoldi / keyingi qadam: T-052 Kirim skaner bilan. T-047 — Q-007.
- Muammo yoki qaror: Excel'da son ko'rinishidagi shtrix-kod kasrsiz matnga aylantiriladi; boshidagi nollar faqat matn katakda saqlanadi, shuning uchun shablonda ustunlar matn formatida. Mavjud tovar qoldig'i import bilan o'zgarmaydi (kirim yoki inventarizatsiya orqali).

## 2026-10-15 — T-052 Kirim skaner bilan
- Qilindi:
  - `ReceiptStore`: lokal qoralama (har o'zgarishda saqlanadi), skan → qator yoki +1, miqdor/tannarx/narx tahriri, yetkazib beruvchini tez yaratish (`supplier.upserted`).
  - Tasdiqlash bitta tranzaksiyada: `stock_movements` (+), tovar narxlari, outbox `receipt.posted`.
  - "Kirim" bo'limi: ro'yxat va tahrirlovchi. Skaner: topildi → qator; noma'lum → tovar kartasi → kirimga. Sariq "narx tannarxdan past" belgisi; kassir uchun menejer PIN.
- Testlar: apps/pos 477 (+23):
  - `ReceiptStore`: 100 skan, tahrir, tasdiqlash → qoldiq va payload, bo'sh kirim, ro'yxat tartibi;
  - 6 ta widget testi: 100 ketma-ket skan, noma'lum kod oqimi, tahrir + PIN + qoldiq, qoralama tiklanishi va o'chirish, yetkazib beruvchi, bo'sh kirim.
  - Golden'lar: `receiving` list/editor × 3 o'lcham × 2 mavzu. Skrinshotlar: `docs/screenshots/T-052/`.
- PR: T-052 (squash merge)
- Qoldi / keyingi qadam: T-053 Inventarizatsiya. Teskari kirim (qaytarish yetkazib beruvchiga) kassada — keyin. Kassirga kirim huquqi "sozlamaga qarab" — hozircha har doim menejer PIN.
- Muammo yoki qaror: telefonda tahrirlovchining pastki paneli ixchamlashtirildi (o'chirish — ikon, tasdiqlash — to'liq kenglikda).

## 2026-10-15 — T-053 Inventarizatsiya skaner bilan
- Qilindi:
  - `CountStore`: qamrov — hamma yoki kategoriya; skan → sanalgan +1; farq = sanalgan − lokal qoldiq; sanalmaganlar ro'yxati.
  - Tasdiqlash bitta tranzaksiyada: `expected` yoziladi, farq bo'lsa `inventory` harakati, outbox `inventory.posted`.
  - Tovarlar → "Inventarizatsiya" (`/products/inventory`): ro'yxat, qamrov tanlash, tahrirlovchi (skaner, qidiruv, farq belgilari, hisobot satri, sanalmaganlar, PIN), tasdiqlangani — faqat o'qish.
- Testlar: apps/pos 490 (+13):
  - `CountStore`: farq, qamrov, tasdiqlash → qoldiq = sanalgan, sanalmagan o'zgarmaydi, payload;
  - 3 ta widget testi: farq hisoboti va tasdiqlash, noma'lum kod va kassir PIN, bo'sh inventarizatsiya va o'chirish.
  - Golden: `inventory/editor` × 3 o'lcham × 2 mavzu (tovarlar ro'yxati golden'i yangi tugma bilan yangilandi). Skrinshotlar: `docs/screenshots/T-053/`.
- PR: T-053 (squash merge)
- Qoldi / keyingi qadam: T-054 Qoldiq harakatlari tarixi va kam qolganlar.
- Muammo yoki qaror:
  - `inventory_count_items` da tartib ustuni yo'q — sxemani o'zgartirmasdan `rowid` (qo'shilish tartibi) ishlatildi.
  - Tarjima testi birlik bilan qo'shib yasalgan yorliqni ushladi: `inventoryCountedUnit` / `receivingQtyUnit` kalitlariga o'tkazildi (kirim tahrirlovchisi ham tuzatildi).

## 2026-10-15 — T-054 Qoldiq harakatlari tarixi va kam qolganlar
- Qilindi:
  - Backend: `GET /api/v1/sync/stock-movements/?product=` (qurilma tokeni, oxirgi 100 ta, kim); `StockMovementTypeEnum` OpenAPI nomi qotirildi.
  - Kassa: tovar kartasida "Harakatlar tarixi" — yuborilmagan lokal harakatlar ("Yuborilmagan" belgisi bilan) va server tarixi; oflaynda faqat lokal harakatlar va izoh.
  - "Kam qolgan" filtrida "Buyurtma ro'yxati" — CSV (UTF-8 BOM, `;`), buyurtma = 2 × min − qoldiq (dona — yuqoriga yaxlitlanadi).
- Testlar:
  - backend +4 (tartib, kim, boshqa tenant 404, 400, JWT yopiq);
  - apps/pos 495 (+5): buyurtma miqdori va CSV, 3 ta widget testi (tarix onlayn/oflayn, CSV eksport).
  - Golden: `products/card_history`. Skrinshotlar: `docs/screenshots/T-054/`.
- PR: T-054 (squash merge)
- Qoldi / keyingi qadam: 4-bosqich (tovarlar va ombor) yopildi; keyingisi — T-060 Mijozlar va nasiya daftari. T-047 — Q-007.
- Muammo yoki qaror:
  - Yangi `type` maydoni OpenAPI enum nomini o'zgartirib yuborgan edi; ENUM_NAME_OVERRIDES bilan qotirildi.
  - Buyurtma formulasi (2 × min) — oddiy boshlang'ich qoida, spec'da yozilgan.

## 2026-10-15 — T-060 Mijozlar va nasiya daftari
- Qilindi:
  - `CustomerDirectory`: tarix, xaridlar, `payDebt` (DebtEntry(−) + outbox `debt.paid` bitta tranzaksiyada, qarzdan ko'p emas), `update` (limit — `by` ega/menejer).
  - "Mijozlar" bo'limi: qarzdorlar tepada, qidiruv, "Qarzi borlar", jami qarz, yangi mijoz.
  - Mijoz kartasi: katta qarz, limit, tarix, xaridlar, to'lov oynasi (summa, "To'liq", naqd/karta), tahrirlash (limit — PIN).
- Testlar: apps/pos 522 (+27):
  - `CustomerDirectory`: balans = Σ yozuvlar, to'lov payload'i, ortiqcha to'lov rad etiladi, tarix, update payload;
  - 5 ta widget testi: tartib/qidiruv/filtr/jami, to'liq to'lov, qisman to'lov, tahrir + limit PIN, yangi mijoz.
  - Golden'lar: `customers` list/card × 3 o'lcham × 2 mavzu. Skrinshotlar: `docs/screenshots/T-060/`.
- PR: T-060 (squash merge)
- Qoldi / keyingi qadam: T-070 Bosh sahifa va hisobotlar. Qo'lda tuzatish (`adjustment`, faqat ega) kassada yo'q.
- Muammo yoki qaror: widget testi "yangi mijoz" oynasidagi xatoni ushladi — controller'lar oyna yopilish animatsiyasidan oldin dispose qilinardi; endi ular oynaning o'z State'ida. Telefonda "Jami qarz" alohida qatorga tushirildi.

## 2026-10-15 — T-070 Bosh sahifa va hisobotlar
- Qilindi:
  - Umumiy vektorlar `testdata/report_vectors.json` (savdo, chek chegirmasi, qisman qaytarish, oldingi kun); server `services` va kassa `LocalReports` ikkalasi shu raqamlarni beradi.
  - Server: `GET /api/v1/sync/reports/` (qurilma tokeni, barcha hisobotlar bitta javobda), OpenAPI + TS/Dart klientlar.
  - Kassa: `reportsProvider` — onlayn server, xato bo'lsa lokal ("faqat shu kassa" belgisi); "Hisobotlar" bo'limi (davr tugmalari, KPI ↑↓%, soat/kun grafigi, to'lov turlari, top tovarlar, kassirlar, qarzlar, ombor); kassirga — menejer PIN.
- Testlar: backend +5 (vektorlar, endpoint, tenant, davr validatsiyasi, JWT yetmaydi); apps/pos 545 (+23): lokal vektorlar, provider (onlayn/oflayn/500), 4 widget testi, golden `reports` today/week × 3 o'lcham × 2 mavzu. Skrinshotlar: `docs/screenshots/T-070/`.
- PR: T-070 (squash merge)
- Qoldi / keyingi qadam: kalendar bilan ixtiyoriy oraliq, xlsx eksport, foyda/miqdor bo'yicha saralash. Keyingi: T-080.
- Muammo yoki qaror: generatsiya qilingan Dart klient `date` query'ni to'liq ISO vaqt qilib yuboradi (server `YYYY-MM-DD` kutadi) — kassa bu endpointni Dio orqali to'g'ridan-to'g'ri chaqiradi, javobni `DeviceReport.fromJson` bilan o'qiydi. `ComingSoonPage` olib tashlandi (bo'sh bo'lim qolmadi).

## 2026-10-15 — T-080 Admin: kirish va layout
- Qilindi:
  - Next route handler'lar `POST /api/auth/login|logout`: Django JWT → httpOnly cookie'lar (`pos_access`, `pos_refresh`), faqat `platform_admin`.
  - `src/proxy.ts`: kirmaganlar `/login?next=` ga; access eskirsa refresh bilan yangilanadi. `(app)/layout.tsx` — `getCurrentAdmin()` (Django `auth/me/`).
  - Kirish sahifasi (uz/ru, yorug'/qorong'i), header'da admin ismi va "Chiqish"; menyu bo'limlari uchun "tayyorlanmoqda" sahifasi.
- Testlar: Vitest 21 (login route handler, proxy, `safeNext`, `LoginForm`), Playwright 8 (himoyalangan sahifa, noto'g'ri parol, ega kira olmaydi, kirish + httpOnly + chiqish, refresh, smoke). Skrinshotlar: `docs/screenshots/T-080/`.
- PR: T-080 (squash merge)
- Qoldi / keyingi qadam: T-081 Admin bosh sahifa (KPI). 2FA — keyinroq (spec).
- Muammo yoki qaror: Next 16 proxy `matcher`ida `\.` saqlanmaydi (kompilyatsiyada `.` bo'lib, hamma yo'lni chiqarib tashlardi) — `favicon.ico` aniq nom bilan. E2E uchun soxta Django API (`e2e/mock-api.mjs`) — CI'da backend ishga tushirilmaydi.

## 2026-10-15 — T-081 Admin: bosh sahifa (KPI)
- Qilindi:
  - `src/lib/platform.ts` — server tomonida Django platforma API (admin tokeni, `401` → login), `getStats()`; `src/lib/format.ts` — pul (tiyin → so'm, NBSP guruhlash) va sana.
  - Bosh sahifa: 4 KPI, oylik tushum grafigi (Recharts), muddati 7 kunda tugaydiganlar ("To'lov kiritish"), sinxronlanmagan qurilmalar; `loading.tsx` skelet, `error.tsx` qayta urinish.
- Testlar: Vitest 32 (+11: dashboard 4, platform 3, format 4), Playwright 11 (+3: KPI/ro'yxat/grafik, ruscha, server xatosi). Soxta API'ga `/platform/stats/` qo'shildi. Skrinshotlar: `docs/screenshots/T-081/`.
- PR: T-081 (squash merge)
- Qoldi / keyingi qadam: T-082 Admin: mijozlar (tenantlar).
- Muammo yoki qaror: `recharts` qo'shildi (spec'dagi grafik kutubxonasi). npm (Windows) lock fayldan `@emnapi/*` optional yozuvlarini olib tashlagan edi — CI `npm ci` yiqildi; yozuvlar main'dagi lock'dan qaytarildi. Planshetda o'ng ustun tor bo'lgani uchun 3 ustunli joylashuv faqat ≥ 1280 px'da.

## 2026-10-15 — T-082 Admin: mijozlar (tenantlar)
- Qilindi:
  - `/tenants`: qidiruv + holat filtri (URL), jadval, sahifalash, CSV; `/tenants/new` 3 qadamli usta va kirish ma'lumotlari kartasi; `/tenants/{id}` tablar (umumiy, to'lovlar, qurilmalar, foydalanuvchilar, faollik), bloklash/blokdan chiqarish, ega/menejer parolini tiklash.
  - Server Actions (`onboardTenant`, `blockTenant`, `unblockTenant`, `resetUserPassword`), `platform.ts` ga tenant funksiyalari; shadcn dialog/table/tabs/select/label/textarea (dialog yopish matni tarjimada).
  - Backend: `GET /platform/payments/` OpenAPI sxemasi ikki marta "paginated" edi — `PaymentPagination` (sxemada `total_tiyin`), TS klient qayta generatsiya.
- Testlar: Vitest 38 (+6: usta 4, csv, formatDateTime), Playwright 17 (+6: qidiruv/filtr, usta → ro'yxat → ega API orqali kiradi, band telefon, bloklash/blokdan chiqarish, tablar, parol tiklash). Soxta API — xotiradagi tenantlar. Skrinshotlar: `docs/screenshots/T-082/`.
- PR: T-082 (squash merge)
- Qoldi / keyingi qadam: T-083 tariflar, obunani uzaytirish (to'lov kiritish), to'lovlar ro'yxati. Ro'yxatda ustun bo'yicha saralash — API'da `ordering` qo'shilganda.
- Muammo yoki qaror: e2e topgan xato — qidiruv debounce eski URL parametrlari bilan holat filtrini bekor qilardi; endi navigatsiya joriy `window.location.search` dan.

## 2026-10-15 — T-083 Admin: tariflar, obunalar, to'lovlar
- Qilindi:
  - `/plans`: tariflar jadvali, yaratish/tahrirlash, nofaol qilish.
  - Mijoz sahifasida "To'lov kiritish" (tarif × oy taklifi, yangi davr oldindan ko'rinadi, `?payment=1`), oxirgi to'lovni bekor qilish (sabab bilan).
  - `/payments`: sana oralig'i, jami netto, sahifalash, CSV.
  - `src/lib/billing.ts` — serverdagi davr formulasi nusxasi (`addMonths`, `previewPeriod`, `tashkentToday`) va `parseSom` (so'm matni → tiyin).
- Testlar: Vitest 55 (+17: billing 13, to'lov oynasi 3, formatSomPlain), Playwright 21 (+4: tarif CRUD, to'lov oldindan ko'rilgan muddatni beradi, faqat oxirgisini bekor qilish va muddat qaytishi, to'lovlar filtri). Backend'da to'lov hisobi testlari (T-013/T-020) — qabul mezoni. Skrinshotlar: `docs/screenshots/T-083/`.
- PR: T-083 (squash merge)
- Qoldi / keyingi qadam: T-084 qurilmalar va audit jurnali.
- Muammo yoki qaror: e2e refresh testi parallel so'rovlarda yiqildi — soxta API refresh'ni bir martalik qilgan edi, Django esa blacklist'siz; mock Django'ga moslandi (spec'ga eslatma).

## 2026-10-15 — T-084 Admin: qurilmalar va audit jurnali
- Qilindi:
  - `/devices`: barcha qurilmalar, filtrlar (3 kundan beri sinxronlanmagan, bloklangan), eski sinxron ajratilgan, bloklash (sabab bilan) / blokdan chiqarish.
  - `/audit`: amal va obyekt turi filtri, mijoz bo'yicha (`?tenant=`), o'zgargan maydonlar (`before → after`) ochiladigan qatorda, sahifalash.
  - `BlockDialog` mijoz va qurilma uchun umumiy; `src/lib/audit.ts` (amallar, obyekt turlari, farq).
- Testlar: Vitest 58 (+3 audit farqi), Playwright 23 (+2: qurilmalar filtrlari va bloklash → auditda; mijoz audit yozuvlari, o'zgarishlar, amal filtri). 5 marta ketma-ket barqaror. Skrinshotlar: `docs/screenshots/T-084/`.
- PR: T-084 (squash merge)
- Qoldi / keyingi qadam: T-085 Obuna nazorati kassa ilovasida (bannerlar, readonly).
- Muammo yoki qaror: (1) `"use client"` moduldan eksport qilingan massiv server sahifada ishlamaydi (client reference) — konstantalar oddiy modulda. (2) Mijozlar filtrida yuklama ostida qidiruv debounce va holat tanlovi bir-birini bekor qilardi — kutilayotgan URL `ref` da saqlanadi.

## 2026-10-15 — T-085 Obuna nazorati ilovada
- Qilindi:
  - `subscription_notice.dart`: oxirgi pull'dagi obuna holati + oflaynda o'tgan kunlar → sinov / tugashiga ≤ 3 kun / grace ogohlantirishi; `supportPhoneProvider`.
  - `SubscriptionBanner` qobiqda (barcha bo'limlar tepasida, ohang bo'yicha); kassa ekranidagi savdo to'xtagan banneri — sabab, nima ishlaydi, aloqa.
  - Kirim va inventarizatsiyani tasdiqlash ham `salesAllowedProvider` ga bog'landi (sync.md shuni talab qilardi).
- Testlar: apps/pos 571 (+26): sof funksiya 5 (oflayn kunlar ham), widget 9 (sinov, tugash, ko'p kun, oflayn sanash, grace, readonly, blocked, oflayn muddati, kirim tasdiqlash o'chiq), golden `subscription` grace/readonly × 3 o'lcham × 2 mavzu. Skrinshotlar: `docs/screenshots/T-085/`.
- PR: T-085 (squash merge)
- Qoldi / keyingi qadam: T-090 Chidamlilik testlari. Aloqa raqami — Q-008.
- Muammo yoki qaror: 7-bosqich (admin dashboard va obuna nazorati) yopildi.
