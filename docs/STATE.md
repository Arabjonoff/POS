# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-014 Katalog API
- Branch: feat/T-014-catalog
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Spec: `docs/specs/catalog-api.md` (endpoint'lar, huquqlar, xato kodlari, shtrix-kod qoidalari, nofaol qilish)
- [ ] 2. `apps/core/fields.py` (StrictIntegerField — pul/miqdor), `apps/catalog/barcodes.py` (normalizatsiya, EAN/UPC nazorat raqami)
- [ ] 3. `apps/catalog` modellari: Category, Unit (tenantga standart birliklar — signal + data migratsiya), Product, ProductBarcode (tenant ichida unique), PriceHistory; admin
- [ ] 4. Serializer/service/viewset: categories, units, products (+ barcodes ro'yxati), `by-barcode/{code}`; manager+ yozadi, a'zo o'qiydi
- [ ] 5. Testlar: CRUD, takroriy shtrix-kod, izolyatsiya, huquqlar, narx tarixi, qat'iy butun son
- [ ] 6. openapi + schema.d.ts; lint/test; PR, CI, merge

## Oxirgi bajarilgan ish
T-012 merge qilindi (#10). Q-001 (A) va Q-002 (B) egasi tomonidan tasdiqlandi. T-014 branch ochildi.

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
2-qadam: `backend/apps/core/fields.py`, `backend/apps/catalog/barcodes.py` + testlar.

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
