# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-015 Ombor (StockMovement, kirim, inventarizatsiya)
- Branch: feat/T-015-inventory
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Spec `docs/specs/inventory-api.md` (harakatlar, kesh, kirim oqimi, teskari kirim, inventarizatsiya, API)
- [x] 2. `apps/inventory` modellari: Supplier, StockMovement (o'zgarmas), ProductStock (kesh), StockReceipt(+Item), InventoryCount(+Item); migratsiya; admin
- [x] 3. `services.py`: record_movement (+kesh), post_receipt, reverse_receipt, post_inventory; `manage.py rebuild_stock`
- [ ] 4. API: suppliers, stock-receipts (+post, +reverse), inventory-counts (+post), stock, stock-movements
- [ ] 5. Testlar: kirim → qoldiq, teskari kirim, inventarizatsiya farqi, qoldiq = yig'indi, o'zgarmaslik, izolyatsiya, huquqlar
- [ ] 6. openapi + schema.d.ts; lint/test; PR, CI, merge

## Oxirgi bajarilgan ish
3-qadam: `services.py` (record_movement + kesh, post_receipt, reverse_receipt, post_inventory, rebuild_stock), `manage.py rebuild_stock`, `TenantPKField` → `apps/core/serializers.py`. 324 test yashil.

## Keyingi aniq harakat
<!-- Bitta aniq buyruq yoki amal. Masalan: "apps/pos/lib/features/cart/cart_controller.dart da removeLine() ni yozish, keyin flutter test test/cart" -->
4-qadam: `backend/apps/inventory/serializers.py`, `views.py`, `urls.py` (suppliers, stock-receipts +post/+reverse, inventory-counts +post, stock, stock-movements); `config/urls.py` ga `apps.inventory.urls` qo'shish.

## Ochiq holatlar
- Commit qilinmagan o'zgarishlar: yo'q
- Ochiq PR: —
- Ishlab turgan servislar: docker compose (pos-*) — 8100, 3100
- Yiqilayotgan testlar: —

## Eslatmalar
<!-- Keyingi sessiya bilishi kerak bo'lgan narsa: topilgan muammo, vaqtinchalik yechim, nima sinab ko'rildi va ishlamadi -->
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*, twf-local-*) tomonidan band. Ularni to'xtatma! POS lokal portlari (.env): postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub, `py -3.12` yo'q; `cd backend && uv run python` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
- Testlar `.env` ni o'qimaydi: `cd backend && DATABASE_URL=postgres://pos:pos@127.0.0.1:55432/pos uv run pytest`.
- 2026-10-14: elektr uzilishi `.git/config` ni nol baytlar bilan buzgan edi; foydalanuvchi qayta tikladi (`[core]` + `origin`).
- Docker Desktop o'chiq bo'lishi mumkin: `C:\Users\Muhammadi\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe` ni ishga tushir, `docker info` javob berguncha kut.
