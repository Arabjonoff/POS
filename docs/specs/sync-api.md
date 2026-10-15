# Sinxronlash API — server (T-018)

Umumiy tamoyillar: `sync.md`. Hodisa payloadlari va qo'llash qoidalari: `sales-api.md`, `customers-api.md`, `inventory-api.md`, `catalog-api.md`. Ikkala endpoint ham **faqat qurilma tokeni** bilan (`Authorization: Device <token>`, `devices.md`); foydalanuvchi JWT'si — `401`.

## Push — `POST /api/v1/sync/push/`
- So'rov: `{events: [{id, type, payload, created_at}]}`, 1–100 ta hodisa (qurilma tokendan aniqlanadi; `device_id` kerak emas). `id` — klient UUID, `created_at` — qurilma vaqti (ISO, vaqt zonasi bilan).
- Hodisalar `created_at` bo'yicha (teng bo'lsa — kelgan tartibda) qo'llanadi. **Har hodisa alohida tranzaksiyada**: birining xatosi boshqasiga ta'sir qilmaydi.
- Javob: `{results: [{id, status, error?}], server_time}` — natijalar so'rovdagi tartibda.
- Statuslar:
  - `applied` — qo'llandi.
  - `duplicate` — bu `id` avval qabul qilingan (qo'llangan, rad etilgan yoki kutilmoqda); ma'lumot o'zgarmaydi. Kassa `applied` kabi belgilaydi.
  - `pending` — bog'liq obyekt (smena, savdo, mijoz) hali serverda yo'q. Server hodisani saqlaydi va **shu qurilmaning har keyingi push'ida** (yangi hodisalardan oldin va keyin) qayta urinadi. Kassa uni yuborilgan deb belgilaydi.
  - `rejected` — biznes yoki format xatosi; `error: {code, message, details}`. Kassa qayta yubormaydi, holat qatorida ogohlantiradi; admin `SyncEvent` jurnalida ko'radi.
- `pending` hodisa **7 kun** ichida qo'llanmasa — `rejected` (`missing_dependency`).

### Ma'lumot yo'qolmasligi qoidalari (T-101, audit)
- **Bog'liq obyekt hali kelmagan** — `pending`, rad etilmaydi: smena, savdo, mijoz, **tovar** (savdo, kirim, inventarizatsiya qatorida).
  Bu id **boshqa tenantda** mavjud bo'lsa — darhol `rejected` (izolyatsiya; hech qachon qo'llanmaydi).
- **Yopilgan smena:** savdo, qaytarish, kassa puli, qarz to'lovi vaqti (`sold_at`/`at`) smena yopilishidan oldin bo'lsa — qabul qilinadi
  (kechikkan yoki kutib turgan hodisa), smenaning `expected_cash_tiyin` qayta hisoblanadi. Yopilgandan keyingi vaqt — `shift_closed`.
- **`product.upserted` butunlay rad etilmaydi** ziddiyat tufayli: boshqa tovarga tegishli shtrix-kod va PLU, o'chirilgan kategoriya tushirib
  qoldiriladi (server logida ogohlantirish); tovarning server holati keyingi pull'da kassaga qaytadi. Aks holda shu tovar bilan bo'lgan barcha
  savdolar ham rad etilardi.
- **Kirim va inventarizatsiya** o'chirilgan tovar va yetkazib beruvchini qabul qiladi (hujjat oflaynda, ular hali mavjud paytda yaratilgan).
- **NUL (`\u0000`)** payload satrlaridan olib tashlanadi (Postgres jsonb saqlay olmaydi; ilgari push 500 berib, navbat to'xtab qolardi).
- Boshqa qurilma yoki tenantga tegishli `id` bilan hodisa — `rejected` (`id_conflict`); mavjud hodisa o'zgarmaydi.
- Noma'lum `type` — `rejected` (`unknown_event`).
- Har push'da `Device.last_sync_at` va `last_seen_at` yangilanadi.

### Hodisa → servis
| `type` | Servis | Payload |
|---|---|---|
| `shift.opened` | `open_shift` | `sales-api.md` |
| `shift.closed` | `close_shift` | `sales-api.md` |
| `cash.moved` | `record_cash_movement` | `sales-api.md` |
| `sale.completed` | `record_sale` | `sales-api.md` |
| `refund.created` | `record_refund` | `sales-api.md` |
| `debt.paid` | `pay_debt(enforce_balance=False)` | `{id, customer, amount_tiyin > 0, method: cash\|card, shift?, by, at, note?}` |
| `customer.upserted` | `CustomerSerializer` | `{id, full_name, phone, note, debt_limit_tiyin?, by}` |
| `supplier.upserted` | `SupplierSerializer` | `{id, name, phone, note, by}` (ega/menejer) |
| `product.upserted` | `ProductSerializer` | `catalog-api.md` mahsulot maydonlari + `by` (ega/menejer) |
| `receipt.posted` | `StockReceiptSerializer` + `post_receipt` | `inventory-api.md` kirim + `by` (ega/menejer) |
| `inventory.posted` | `InventoryCountSerializer` + `post_inventory` | `inventory-api.md` inventarizatsiya + `by` (ega/menejer) |

- `by` — amalni bajargan xodim (tenant foydalanuvchisi). Huquq REST bilan bir xil: kassir tovar/kirim/inventarizatsiya yoza olmaydi, mijozga limit qo'ya olmaydi → `rejected` (`permission_denied`).
- `*.upserted`: `id` bo'yicha bor bo'lsa — yangilanadi, yo'q bo'lsa — yaratiladi. Konflikt qoidasi: **server g'olib** — o'zgarish serverga yoziladi va pull orqali hamma qurilmaga qaytadi.

## Pull — `GET /api/v1/sync/pull/?cursor=<str>&limit=<1..500>`
- `cursor` — oldingi javobdagi `next_cursor` (ochiq bo'lmagan satr, `"<txid>:<seq>"`; birinchi marta `"0"`). `limit` — standart 500. Noto'g'ri kursor — `400`.
- Javob: `{changes: [{entity, op, id, data}], next_cursor, has_more, subscription: {status, paid_until, days_left, offline_days}, server_time}`.
- `op`: `upsert` (data — obyektning hozirgi holati) yoki `delete` (yumshoq o'chirilgan; `data: null`).
- Sahifa ichida bir obyekt bir marta (eng oxirgi o'zgarish). Tartib — `(txid, seq)` bo'yicha (pastga qarang).
- Entitylar va `data` shakli:
  | `entity` | Shakl |
  |---|---|
  | `unit`, `category`, `product` (shtrix-kodlar ichida), `supplier`, `customer` (balans bilan) | REST serializerlari bilan bir xil |
  | `user` | `{id, phone, full_name, role, is_active, pin_hash}` — faqat do'kon xodimlari |
  | `store` | `{id, name, address, phone, receipt_header, receipt_footer}` |
  | `debt_entry` | `customers-api.md` |
  | `stock` | `{product, store, qty_milli, updated_at}` (`id` — tovar) |
- Faqat qurilma tenantining o'zgarishlari.

## ChangeLog
- `ChangeLog {seq (BigAutoField), txid, tenant, entity, entity_id, op, at}` — yuqoridagi entitylar o'zgarganda yoziladi (signal; `ProductStock` `update()` bilan o'zgargani uchun — `record_movement` ichida aniq yozuv).
- `ProductBarcode` o'zgarishi — `product` upsert sifatida.
- Joriy ma'lumot uchun migratsiya boshlang'ich yozuvlarni yaratadi (yangi qurilma `cursor=0` dan hammasini oladi).
- **Teshiksiz kursor:** `seq` commit'dan oldin ajratiladi — kichik `seq` li tranzaksiya kattasidan keyin commit bo'lishi mumkin va oddiy `seq > cursor` uni o'tkazib yuboradi. Shuning uchun har yozuvda uni yozgan PostgreSQL tranzaksiya ID'si (`txid`) saqlanadi; pull faqat `txid < pg_snapshot_xmin(...)` (barcha eski tranzaksiyalar tugagan) yozuvlarni `(txid, seq)` tartibida beradi. Bunday yozuvlar orasiga keyin yangisi tushmaydi. Uzoq tranzaksiya tugaguncha keyingi o'zgarishlar biroz kechikadi — bu maqbul.

## Narx tarixi — `GET /api/v1/sync/price-history/?product=<uuid>` (T-050)
- Faqat qurilma tokeni bilan; tovar qurilma tenantida bo'lishi shart (boshqa tenant yoki noma'lum — `404`, noto'g'ri UUID — `400`).
- Javob: `catalog-api.md` dagi `price-history` bilan bir xil (oxirgi 50 ta, eng yangisi birinchi). Kassada faqat menejer/ega ko'radi (lokal PIN); oflaynda — "Internet kerak".

## Qoldiq harakatlari — `GET /api/v1/sync/stock-movements/?product=<uuid>` (T-054)
- Faqat qurilma tokeni bilan; tovar qurilma tenantida bo'lishi shart (aks holda `404`, noto'g'ri UUID — `400`).
- Javob: oxirgi 100 ta harakat (barcha kassalar, eng yangisi birinchi): `[{id, type, qty_milli, ref_type, at, created_by_name}]`.
