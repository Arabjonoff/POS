# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-013 Tariflar va obuna
- Branch: feat/T-013-billing
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. `QUESTIONS.md` Q-001/Q-002 (sinovdan keyin grace; sinov ichida to'lov) + `subscription-billing.md` sana semantikasi
- [ ] 2. `apps/billing`: Plan, Subscription (cached status), SubscriptionPayment (o'zgarmas, teskari yozuv), migratsiya, admin
- [ ] 3. `status.py` (sof funksiya `compute_status`, `add_months`) + `services.py` (start_subscription, record_payment, reverse_payment, refresh_status)
- [ ] 4. `manage.py update_subscriptions`
- [ ] 5. Testlar (≥ 8 holat parametrlangan, to'lov matematikasi, bekor qilish, buyruq)
- [ ] 6. lint/test/schema; PR, CI, merge

## Oxirgi bajarilgan ish
T-011 merge qilindi (#8); dev baza qayta yaratildi (foydalanuvchi ruxsati bilan), migratsiyalar qo'llandi. T-013 branch ochildi.

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
2-qadam: `backend/apps/billing` (models.py, admin.py, apps.py), INSTALLED_APPS, makemigrations.

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: docker compose (pos-*) — 8100, 3100
- Yiqilayotgan testlar: —

## Eslatmalar
<!-- Keyingi sessiya bilishi kerak bo'lgan narsa: topilgan muammo, vaqtinchalik yechim, nima sinab ko'rildi va ishlamadi -->
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*, twf-local-*) tomonidan band. Ularni to'xtatma! POS lokal portlari (.env): postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub, `py -3.12` yo'q; `cd backend && uv run python` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
- Docker Desktop o'chiq bo'lishi mumkin: `C:\Users\Muhammadi\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe` ni ishga tushir, `docker info` javob berguncha kut.
