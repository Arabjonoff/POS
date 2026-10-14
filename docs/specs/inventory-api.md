# Ombor API (T-015): qoldiq, kirim, inventarizatsiya

Foydalanuvchi JWT'si bilan. **Yozish** (kirim, inventarizatsiya, yetkazib beruvchilar) — owner va manager. **O'qish** (qoldiq, harakatlar, yetkazib beruvchilar) — tenantning istalgan xodimi. Kirim va inventarizatsiya hujjatlarini (o'qish ham) — faqat owner va manager (tannarx ko'rinadi). Boshqa tenant obyekti — `404`, payload'da begona `product`/`supplier`/`store` — `400`. Miqdor — `*_milli` (1 dona = 1000), pul — `*_tiyin`, faqat butun son.

## Qoldiq
- **Manba — `StockMovement`** (faqat qo'shiladi, o'zgarmaydi, o'chirilmaydi). Qoldiq = `SUM(qty_milli)` (tovar + do'kon).
- `ProductStock` — kesh (tovar + do'kon → `qty_milli`), har harakat bilan **o'sha tranzaksiyada** yangilanadi. Mos kelmasa — `manage.py rebuild_stock` qayta hisoblaydi (manba — harakatlar).
- Harakat turlari: `receipt` (kirim; teskari kirimda manfiy), `sale`, `refund`, `adjustment`, `inventory`. `ref_type` + `ref_id` — qaysi hujjatdan.
- Manfiy qoldiq ruxsat (sotuvni bloklamaydi, `sync.md`).
- `GET /api/v1/stock/` — `{product, store, qty_milli, updated_at}`. Filtrlar: `?product=`, `?store=`, `?low=true` (`min_stock_milli > 0` va qoldiq undan kam), `?negative=true`. Faqat kamida bitta harakati bor tovarlar qatori bor; hech qachon kirim qilinmagan tovar `low` ro'yxatiga tushmaydi (to'liq "kam qolganlar" — T-054).
- `GET /api/v1/stock-movements/` — harakatlar tarixi (yangisi birinchi). Filtrlar: `?product=`, `?store=`, `?type=`. Noto'g'ri UUID — `400`.

## Yetkazib beruvchilar — `/api/v1/suppliers/`
- `{id, name, phone, note}`; CRUD; o'chirish — yumshoq.

## Kirim — `/api/v1/stock-receipts/`
- Qoralama: `POST {id?, supplier?, store?, note, items: [{product, qty_milli > 0, cost_price_tiyin ≥ 0, new_sell_price_tiyin?}]}`. `store` berilmasa — tenantning birinchi do'koni. `PATCH` — faqat qoralama (`items` yuborilsa — almashtiriladi). Tasdiqlangandan keyin tahrir — `409 receipt_not_draft`.
- `number` — tenant ichida tartib raqami (server beradi; tenant qatori qulflanadi — parallel so'rovlarda takrorlanmaydi).
- `id` klientda yaratilishi mumkin (UUIDv7); band bo'lsa — `400`. `PUT` yo'q, faqat `PATCH`. Ro'yxat filtri: `?status=draft|posted`.
- `total_cost_tiyin` = Σ `line_total(cost_price_tiyin, qty_milli)` (half-up, `money.py`).
- `POST /{id}/post/` — **bitta tranzaksiya**: status `posted`, har qatorga `receipt` harakati (+qty), tovar tannarxi = qator tannarxi, `new_sell_price_tiyin` bo'lsa sotish narxi yangilanadi, narx o'zgarsa `PriceHistory`. Bo'sh kirim — `400 receipt_empty`.
- `POST /{id}/reverse/` — tasdiqlangan kirimni teskari qiladi: yangi kirim (`reverses` → asl, status `posted`) manfiy harakatlar bilan. Narxlar qaytarilmaydi. Ikkinchi marta — `409 already_reversed`; qoralamani — `409 receipt_not_posted`; teskari kirimni teskari qilib bo'lmaydi — `409 cannot_reverse_reversal`.
- Qoralamani o'chirish (`DELETE`) mumkin; tasdiqlanganini — `409 receipt_not_draft`.

## Inventarizatsiya — `/api/v1/inventory-counts/`
- Qoralama: `POST {id?, store?, scope: all|category, category?, note, items: [{product, counted_milli ≥ 0}]}`. `PATCH` — faqat qoralama.
- `POST /{id}/post/` — **bitta tranzaksiya**: har qator uchun `expected_milli` = shu paytdagi qoldiq (keshdan) yoziladi, farq `counted − expected` ≠ 0 bo'lsa `inventory` harakati. **Sanalmagan tovarlar o'zgarmaydi** (ma'lumotni tasodifan nolga tushirmaslik uchun); `scope` — ma'lumot uchun (ekranda qaysi tovarlar ro'yxatlangani).
- Bir tovar qatorlarda takrorlansa — `400`.
- Tasdiqlangan inventarizatsiya o'zgarmaydi: `post`, `PATCH`, `DELETE` — `409 count_not_draft`. Bo'sh — `400 count_empty`. Qoralamani o'chirish mumkin.
- `scope=category` uchun `category` majburiy; `scope=all` da `category` tozalanadi. Javobda har qatorda `diff_milli` (`counted − expected`, qoralamada `null`).

## Kassada inventarizatsiya (T-053)
- **Tovarlar → "Inventarizatsiya"** (`/products/inventory`): ro'yxat (qoralamalar birinchi) va "Yangi inventarizatsiya" — qamrov: hamma tovarlar yoki bitta kategoriya.
- **Qoralama** — `apps/pos/lib/data/inventory/count_store.dart` (`CountStore`), lokal `inventory_counts`/`inventory_count_items`, har o'zgarishda saqlanadi.
- **Skaner**: har skan — sanalgan +1 (tarozi kodi — vazni bilan). Noma'lum kod → "avval tovar qo'shing". Qidiruv bilan qo'shish ham mumkin.
- **Qatorda**: tizimda (hozirgi lokal qoldiq), sanalgan (tahrirlanadi), farq (ortiqcha — sariq, kam — qizil).
- **Hisobot**: sanalgan / sanalmagan (qamrovdagi faol tovarlar) / ortiqcha / kam. Sanalmaganlarni bosib qo'shish mumkin. Ular tasdiqlashda **o'zgarmaydi**.
- **Tasdiqlash** — bitta tranzaksiya:
  - har qatorga `expected_milli` (shu paytdagi lokal qoldiq) yoziladi;
  - farq ≠ 0 bo'lsa — `stock_movements` (`inventory`, ±farq), natijada qoldiq = sanalgan;
  - outbox `inventory.posted` `{id, scope, category, note, items: [{product, counted_milli}], by}`;
  - server o'z `expected` ini qo'llash paytida hisoblaydi — natija bir xil (qoldiq = sanalgan).
  - Kassir bo'lsa menejer/ega PIN so'raladi. Bo'sh inventarizatsiyani tasdiqlab bo'lmaydi. Tasdiqlangani faqat o'qish uchun (farq hisoboti saqlanadi).
