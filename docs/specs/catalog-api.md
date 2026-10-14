# Katalog API (T-014)

Foydalanuvchi JWT'si bilan. **O'qish** — tenantning istalgan xodimi (owner, manager, cashier). **Yozish** — owner va manager. Kassa katalogni asosan sinxron (pull) orqali oladi; bu API — ega/menejer ekranlari va onlayn qidiruv uchun.

Barcha ro'yxatlar paginatsiyalangan (`?page=`, 50 tadan). Boshqa tenant obyekti — `404`; payload'da boshqa tenant `category`/`unit` — `400 validation_error`.

## Birliklar — `/api/v1/units/`
- Maydonlar: `id, code, name, is_fractional`. `code` tenant ichida unique.
- Yangi tenantga standart birliklar avtomatik: `pcs` (dona), `kg`, `g`, `l`, `m` (kasrli: kg, l, m), `pack`. Standart birliklar `name` bo'sh — klient `code` bo'yicha tarjima faylidan ko'rsatadi. O'z birligi — `name` majburiy.
- O'chirish — tovarlarda ishlatilsa `409 unit_in_use`; aks holda yumshoq o'chirish.

## Kategoriyalar — `/api/v1/categories/`
- Maydonlar: `id, name, parent, sort, color` (`color` — dizayn palitrasi kaliti, masalan `green`; ixtiyoriy).
- O'chirish — yumshoq (`deleted_at`); shu kategoriyadagi tovarlar kategoriyasiz qoladi; ichki kategoriyalar ham o'chiriladi.

## Tovarlar — `/api/v1/products/`
- Maydonlar: `id` (ixtiyoriy, klient UUIDv7), `name`, `category?`, `unit`, `sell_price_tiyin`, `cost_price_tiyin` (default 0), `is_weighted`, `plu_code?`, `min_stock_milli`, `ikpu_code?`, `quick_button`, `is_active`, `barcodes: [string]` (birinchisi — asosiy), `markup_bp` (faqat o'qish: ustama, bazis punktda — `(narx − tannarx) × 10000 / tannarx`, tannarx 0 bo'lsa `null`).
- Pul va miqdor — faqat butun son (JSON number, kasrsiz). `150.5`, `"150"`, `true` — `400`.
- `barcodes` yuborilsa — tovar shtrix-kodlari shu ro'yxat bilan almashtiriladi (yo'qlari yumshoq o'chiriladi).
- Filtrlar: `?search=` (nom bo'yicha qisman, shtrix-kod va PLU bo'yicha aniq), `?category=`, `?is_active=true|false`, `?quick_button=true`.
- `DELETE` — **nofaol qilish** (`is_active=false`), tarix va shtrix-kodlar saqlanadi; javob `204`.
- Narx (`sell_price_tiyin`, `cost_price_tiyin`) yaratishda va har o'zgarganda `PriceHistory` ga yoziladi (kim, qachon).
- `GET /api/v1/products/{id}/price-history/` — narx tarixi (eng yangisi birinchi, oxirgi 50 ta): `[{id, sell_price_tiyin, cost_price_tiyin, changed_by, changed_by_name, at}]`. Faqat ega va menejer (kassir — `403`), boshqa tenant — `404`. Kassa uchun qurilma tokeni bilan — `GET /api/v1/sync/price-history/?product=` (`sync-api.md`).
- `GET /api/v1/products/by-barcode/{code}/` — shtrix-kod bo'yicha (bosh/oxirgi bo'shliqlar olib tashlanadi, boshidagi nollar saqlanadi). Nofaol tovar ham qaytadi (`is_active: false` — kassa ogohlantiradi). Topilmasa `404`.

## Shtrix-kod qoidalari
- Matn (son emas), 4–64 belgi, faqat ko'rinadigan ASCII belgilar, bo'shliqsiz.
- Faqat raqamdan iborat 8, 12, 13 belgili kod — EAN-8 / UPC-A / EAN-13 nazorat raqami tekshiriladi; noto'g'ri — `400 validation_error` (`invalid_check_digit`).
- Tenant ichida unique (o'chirilmaganlar orasida). Boshqa tovarda bor — `409 barcode_taken`, `details: {barcode, product: {id, name}}`. Bir so'rovda takrorlansa — `400`.
- Boshqa tenantda bir xil kod — ruxsat.

## Vaznli tovar
- `is_weighted=true` — birlik kasrli bo'lishi shart (`kg`), aks holda `400`.
- `plu_code` — aniq 5 raqam (tarozi formati, `barcode.md`); tenant ichida unique (faol tovarlar orasida) — `409 plu_taken`.
