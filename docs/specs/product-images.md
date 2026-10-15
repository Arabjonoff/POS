# Mahsulot rasmi (T-105, qaror 0013)

## Foydalanuvchi uchun
- **Tovar kartasi:** "Rasm (ixtiyoriy)" — katta ko'rinish (120 dp), **Rasm qo'shish / Almashtirish / Olib tashlash**. Tanlangan rasm darhol
  ko'rinadi; tovar saqlanganda saqlanadi ("Bekor qilish" — o'zgarishsiz). Serverga hali yetmagan bo'lsa — "Internetga hali yuklanmagan".
- **Ro'yxat** (jadval va telefon kartalari) va **kassa qidiruvi**: kichik rasm (40/56 dp). Rasm yo'q, hali yuklab olinmagan yoki o'qilmasa —
  placeholder (tovar ikoni). Ekran hech qachon tarmoqni kutmaydi.
- Fayl: JPG, PNG, WebP, BMP... (≤ 20 MB). Kassada JPEG ga aylantiriladi: eng uzun tomoni 800 px, sifat 80 (~50–150 KB), burilish to'g'rilanadi,
  shaffof joy oq.
- Huquq: tovar kartasi bilan bir xil — ega/menejer (kassir — menejer PIN).

## Ma'lumot
- Rasm — **o'zgarmas obyekt**, id kassada (UUIDv7). Almashtirish — yangi id: fayl va kesh abadiy.
- **Kassa:** `products.image_id`; fayl — ilova papkasi `product_images/<id>.jpg` (vaqtinchalik fayl → nomini o'zgartirish). Navbat/kesh jadvali
  `product_images {id, product_id, state, by, attempts, next_attempt_at, last_error}`: `local` → `uploaded`; `remote` (yuklab olingan);
  `delete` (serverdan o'chirish); `failed` (server qabul qilmadi).
- **Server:** `ProductImage {id, product, file (≤ 800), thumb (≤ 200), sha256, width, height, bytes, uploaded_by, deleted_at}`, `Product.image`.
  Fayllar `MEDIA_ROOT` (`media` volume), **ochiq URL yo'q**.

## Sinxron (JSON outbox'dan alohida)
- Rasm baytlari outbox'dan o'tmaydi (outbox kichik, tez, NUL-xavfsiz). `SyncEngine` push → pull'dan keyin `ProductImageSync.run`:
  - **yuklash:** `PUT /api/v1/sync/product-images/{id}/` (multipart: `file`, `product`, `by`) — 2 tadan; `409 product_missing` (tovar hodisasi
    hali qo'llanmagan) — kutish (30 s → 30 daq); `400` — `failed`; tarmoq yo'q — keyingi sikl.
  - **o'chirish:** `DELETE ...{id}/ {by}`.
  - **yuklab olish:** rasmi bor, lekin fayli yo'q tovarlar → `GET ...{id}/` (siklda ≤ 20 ta).
  - Bu qadamdagi har qanday xato push/pull holatiga ta'sir qilmaydi.
- **Server:** qurilma tokeni, faqat o'z tenanti (begona — 404/409); `by` — ega/menejer; Pillow bilan tekshiruv (JPEG/PNG/WebP, ≤ 5 MB,
  ≤ 4096 px, dekompressiya bombasidan himoya), qayta kodlash, EXIF olib tashlanadi; takroriy id — o'zgarishsiz (200).
  `GET` — `Cache-Control: private, max-age=31536000, immutable`, `ETag` = sha256.
- **Pull:** `product.image {id, sha256, width, height} | null` (faqat o'qish). `product.upserted` rasmga **tegmaydi** — eski snapshot rasmni
  o'chirmaydi. Kassada hali yuklanmagan (`local`) yoki o'chirilayotgan (`delete`) rasm bo'lsa, pull `image_id` ni bosmaydi.
- Eski kassa: `image` kalitini e'tiborsiz qoldiradi.

## Infra
- `docker-compose.prod.yml`: `media` volume (backend `/app/media`, zaxira `/media`); kunlik zaxira `media-*.tar.gz` (`deploy/backup.sh`),
  tiklash — `restore.sh <dump> [media.tar.gz]`; Caddy `request_body max_size 8MB`.
