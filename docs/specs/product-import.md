# Tovarlarni Excel/CSV dan import qilish (T-051)

Qaror: `docs/decisions/0009-server-side-product-import.md` — fayl **serverda** o'qiladi va qo'llanadi. Kassa faylni yuboradi, moslashni ko'rsatadi, natijani pull orqali oladi. Import uchun internet kerak.

## Oqim (kassa → Tovarlar → "Excel'dan yuklash")
1. **Fayl**: `.xlsx` yoki `.csv` tanlanadi. "Shablonni yuklab olish" — tayyor ustunlar bilan `.xlsx`.
2. **Ustunlarni moslash**: server sarlavhalarni o'qiydi va moslashni taklif qiladi (nom, shtrix-kod, kategoriya, birlik, narx, tannarx, qoldiq). Kassir har maydon uchun ustunni tanlaydi yoki "yo'q" deb belgilaydi. Birinchi 20 qator ko'rsatiladi.
3. **Tekshirish** (quruq ishga tushirish, bazaga yozmaydi): yangi / yangilanadigan / xato qatorlar soni, xatolar ro'yxati (Excel qator raqami + sabab).
4. **Import**: to'g'ri qatorlar **bitta tranzaksiyada** qo'llanadi, xato qatorlar o'tkazib yuboriladi. Keyin kassa darhol pull qiladi va natija xabari ko'rinadi.

## Qoidalar
- Majburiy maydonlar — nom va narx (moslash ham, qiymat ham). Birlik berilmasa — `dona`.
- **Mavjud tovar shtrix-kod bo'yicha topiladi** (faol yoki nofaol, o'chirilmagan): nom, narx, tannarx, kategoriya, birlik yangilanadi. Shtrix-kodsiz qator yoki noma'lum kod — yangi tovar.
- Shtrix-kod: `catalog-api.md` qoidalari (format, EAN nazorat raqami). Fayl ichida takrorlansa — ikkinchisi xato (`duplicate_in_file`).
- Kategoriya nomi bo'yicha (katta-kichik harf farqsiz); yo'q bo'lsa — **yaratiladi**.
- Birlik: kod yoki nom (`pcs`, `dona`, `шт`, `kg`, `кг`, `g`, `l`, `л`, `m`, `pack`, `quti`, ...) — tenant birliklari orasidan; topilmasa — xato.
- Pul — so'mda (`12500`, `12 500`, `12500,50`, Excel soni) → tiyin (`int`, half-up 2 xonagacha). Manfiy yoki narx 0 — xato.
- Qoldiq (ixtiyoriy) — faqat **yangi** tovarlar uchun, `> 0` bo'lsa: hammasi bitta tasdiqlangan kirim (`StockReceipt`, izoh "Import") bo'lib yoziladi. Mavjud tovar qoldig'i import bilan o'zgarmaydi (kirim yoki inventarizatsiya orqali).
- Narx o'zgarsa — `PriceHistory` (`changed_by` = `by`).
- Excel'dagi raqamli shtrix-kod (son katak) — butun songa aylantiriladi (`4.78e12` → `4780000000014`); boshidagi nollar faqat matn katakda saqlanadi (shablonda ustun — matn).
- Cheklovlar: fayl ≤ 10 MB, ≤ 20 000 qator; 5000 qator bir necha soniyada qo'llanadi.

## API (qurilma tokeni bilan, `sync-api.md` dagidek)
- `GET /api/v1/sync/product-import/template/` → `.xlsx` (sarlavhalar: Nomi, Shtrix-kod, Kategoriya, Birlik, Narx, Tannarx, Qoldiq; ustunlar matn formatida, bitta namuna qator).
- `POST /api/v1/sync/product-imports/` (multipart `file`) → `{id, columns: [str], sample: [[str]], total_rows, mapping}` — `mapping`: `{name, barcode, category, unit, sell_price, cost_price, stock}` → ustun indeksi yoki `null` (taklif). Format xato — `400 invalid_file`, katta — `400 file_too_large` / `too_many_rows`.
- `POST /api/v1/sync/product-imports/{id}/check/` `{mapping}` → `{creates, updates, errors: [{row, field, code}], error_count}` (errors — birinchi 500 tasi).
- `POST /api/v1/sync/product-imports/{id}/apply/` `{mapping, by}` → `{created, updated, skipped, errors, error_count, receipt}`; `by` — tenantning ega/menejeri (aks holda `400`). Qayta `apply` — `409 import_already_applied`.
- Import yozuvi (`ProductImport`) 24 soat saqlanadi; boshqa tenant yoki qurilma — `404`.
- Xato kodlari: `required`, `invalid_number`, `not_positive`, `invalid_barcode`, `invalid_check_digit`, `duplicate_in_file`, `barcode_taken` (boshqa tovarda, yangilash mumkin bo'lmasa), `unknown_unit`, `too_long`.

## Kassa
- Tovarlar ekranida "Excel'dan yuklash" (bo'sh holatda ham). Oflaynda — "Import uchun internet kerak".
- Kassir boshlasa, `apply` oldidan menejer/ega PIN so'raladi (`by`).
- Moslash: har maydon yonida ustun tanlovi; namunaviy jadval (20 qator).
- Natija: "Qo'shildi: N, yangilandi: M, o'tkazib yuborildi: K" va xatolar ro'yxati (qator, sabab).
