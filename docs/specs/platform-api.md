# Platforma admin API (T-020)

SaaS egasi (platform_admin) uchun — admin dashboard (`admin-dashboard.md`) shu API'ni ishlatadi. Barcha yo'llar `/api/v1/platform/...`, **faqat `platform_admin`** (JWT). Do'kon xodimlari (ega, menejer, kassir) — `403`; anonim — `401`.

## Audit qoidasi
- **Har o'zgarish** (POST/PATCH/DELETE, bloklash, to'lov, parol tiklash) `AdminAuditLog` ga yoziladi: `{actor, action, target_type, target_id, tenant?, before, after, reason, at}`. Yozuv o'zgarishning o'zi bilan **bitta tranzaksiyada** — biri bo'lmasa, ikkinchisi ham yo'q.
- `before`/`after` — o'zgargan obyektning JSON ko'rinishi (yaratishda `before = null`). Parollar, PIN va token xeshlari hech qachon yozilmaydi.
- Audit jurnali o'zgarmas (`AppendOnlyModel`); `GET /platform/audit-log/` — `?tenant=`, `?actor=`, `?target_type=`, `?action=` filtrlari, yangisi birinchi.

## Tenantlar — `/platform/tenants/`
- Ro'yxat: `{id, name, owner_phone, owner_name, plan, status, paid_until, trial_ends_at, devices_count, last_activity_at, is_blocked, created_at}`. `?search=` (nom yoki telefon), `?status=trial|active|grace|readonly|blocked`. `last_activity_at` — qurilmalarning eng oxirgi `last_seen_at`.
- Karta (`/{id}/`): ro'yxat maydonlari + `address, timezone, default_locale, notes, blocked_reason, subscription {plan, trial_ends_at, paid_until, grace_days, offline_days, status, days_left}, users_count`.
- **Onboarding** `POST`: `{name, address?, timezone?, default_locale?, notes?, owner: {phone, full_name, password?}, plan, trial_days (0..90, standart 14)}` → bitta tranzaksiyada: Tenant (+ Store, standart birliklar), ega (`role=owner`), obuna (sinov). `password` berilmasa — vaqtinchalik parol generatsiya qilinadi (10 belgi) va **faqat shu javobda** qaytadi: `{tenant, owner: {id, phone, full_name}, temporary_password}`. Telefon band — `409 phone_taken`.
- `PATCH /{id}/` — `name, address, timezone (IANA), default_locale, notes`.
- `POST /{id}/block/` `{reason}` (majburiy) / `POST /{id}/unblock/` → karta.
- `PATCH /{id}/subscription/` — `plan, grace_days, offline_days, trial_ends_at` → holat qayta hisoblanadi.
- `GET /{id}/users/` — xodimlar; `POST /platform/users/{id}/reset-password/` — faqat ega/menejer (parolli rollar), yangi vaqtinchalik parol javobda.
- `GET /{id}/sync-events/?status=rejected|pending|applied` — qurilma hodisalari (yangisi birinchi).
- Tenant o'chirilmaydi (ma'lumot hech qachon o'chirilmaydi).

## Tariflar — `/platform/plans/`
- CRUD: `{id, name, price_tiyin_per_month, max_devices, max_users, features, is_active, sort, subscribers_count}`. `DELETE` — nofaol qilish (`is_active=false`), obunalar saqlanadi.

## To'lovlar
- `POST /platform/tenants/{id}/payments/` `{amount_tiyin, months, method, note?}` → `record_payment` (`subscription-billing.md`).
- `GET /platform/payments/` — barcha to'lovlar (`?tenant=`, `?date_from=`, `?date_to=` — `paid_at` sanasi, Asia/Tashkent), javobda sahifa + `total_tiyin` (filtrlangan, bekor qilinganlar bilan netto).
- `POST /platform/payments/{id}/reverse/` `{note}` (majburiy) → `reverse_payment`; faqat oxirgi to'lov (`409`).

## Qurilmalar — `/platform/devices/`
- `{id, tenant, tenant_name, code, name, platform, app_version, last_sync_at, last_seen_at, is_blocked, created_at}`; `?tenant=`, `?blocked=true`, `?stale_days=N` (oxirgi sinxron N kundan oldin yoki umuman yo'q).
- `POST /{id}/block/` `{reason}` / `POST /{id}/unblock/`.

## Statistika — `GET /platform/stats/`
- `tenants: {total, trial, active, grace, readonly, blocked}` — `subscription_status` bo'yicha (bugun).
- `mrr_tiyin` = Σ tarif oylik narxi (holati `active` yoki `grace` bo'lganlar).
- `revenue_this_month_tiyin` = Σ to'lovlar (`paid_at` shu oyda, Asia/Tashkent; bekor qilishlar manfiy).
- `expiring_soon` — `active` va to'langan muddati 7 kun ichida tugaydiganlar: `[{tenant, name, paid_until, days_left}]` (eng yaqini birinchi).
- `stale_devices` — bloklanmagan, 3 kundan beri sinxronlanmagan qurilmalar soni.
- `monthly_revenue` — oxirgi 12 oy: `[{month: "YYYY-MM", revenue_tiyin}]`.
