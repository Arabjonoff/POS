# Tovarlar

## Ro'yxat
- Qidiruv (nom, shtrix-kod, PLU), kategoriya filtri, "kam qolgan", "manfiy qoldiq", "nofaol" filtrlari.
- Ustunlar (desktop): nom, shtrix-kod, kategoriya, narx, tannarx, qoldiq, holat. Telefon: kartalar.
- Bo'sh holat: "Hali tovar yo'q" + "Tovar qo'shish" va "Excel'dan yuklash".

## Tovar kartasi
- Majburiy: nom, birlik, sotish narxi. Ixtiyoriy: kategoriya, tannarx, shtrix-kodlar (bir nechta, skaner bilan), vaznli tovar + PLU, min qoldiq, IKPU, tez tugmada ko'rsatish.
- Ustama foizi avtomatik ko'rsatiladi (narx − tannarx).
- Saqlash → `product.upserted` outbox. O'chirish = nofaol qilish (tarix saqlanadi).

## Import
- Shablon (xlsx): nom, shtrix-kod, kategoriya, birlik, narx, tannarx, qoldiq (ixtiyoriy — boshlang'ich kirim sifatida).
- Ustunlarni moslash, 20 qator oldindan ko'rish, xatolar (qator raqami + sabab), shtrix-kod bo'yicha mavjudlarini yangilash.

## Kassada amalga oshirilishi (T-050)
- **Bo'lim "Tovarlar"** (Ctrl+2) — `apps/pos/lib/features/products/products_screen.dart`:
  - qidiruv: nom lotin/kirill farqsiz, so'zlar istalgan tartibda; shtrix-kod boshi ≥ 3 belgi; aniq PLU;
  - holat filtri: Hammasi (faol) / Kam qolgan / Manfiy qoldiq / Nofaol; kategoriya chiplari.
- **Ko'rinish**: desktop'da jadval (nom, shtrix-kod, kategoriya, narx, tannarx, qoldiq; nom, narx va qoldiq bo'yicha saralanadi). 1000 px dan tor jadvalda shtrix-kod va tannarx yashiriladi, qoldiq doim ko'rinadi. Telefonda kartalar. Bo'sh holat: "Hali tovar yo'q" + "Tovar qo'shish".
- **Qoldiq** (`stockQuery`): `product_stock` (server) + hali yuborilmagan lokal harakatlar (outbox `status != sent`). "Kam qolgan" — faol, `min_stock > 0` va qoldiq ≤ min. "Manfiy" — qoldiq < 0.
- **Skaner** ro'yxatda: kod bor bo'lsa — tovar kartasi, yo'q bo'lsa — yangi karta, shtrix-kod to'ldirilgan. Karta ochiq paytda skanerlangan kod ro'yxatga qo'shiladi. Boshqa tovardagi kod uchun "«kod» — «tovar» tovarida bor" ogohlantirishi chiqadi.
- **Tovar kartasi** (`product_card.dart`):
  - maydonlar: nom, birlik, kategoriya, sotish narxi va tannarx (so'm, ustama % darhol), shtrix-kodlar (birinchisi — asosiy), vaznli + PLU, minimal qoldiq, IKPU, tez tugma; "Nofaol qilish / Faollashtirish".
  - tekshiruv (`ProductEditor.validate`, server qoidalari bilan bir xil): nom va birlik majburiy; narx > 0; shtrix-kod formati, EAN nazorat raqami, takrori va boshqa tovarda bandligi; PLU 5 raqam va faol tovarlar orasida yagona; vaznli tovar — faqat kasrli birlik; IKPU 17 raqam.
- **Saqlash** — lokal baza (kassa katalogi darhol yangilanadi) + outbox `product.upserted` bitta tranzaksiyada. Server `by` ni faqat ega/menejerdan qabul qiladi: kassir saqlasa menejer/ega PIN so'raladi, menejer/ega o'zi bo'lsa PIN so'ralmaydi.
- **Narx tarixi** (faqat menejer/ega, mavjud tovar): onlayn `GET /api/v1/sync/price-history/?product=` (qurilma tokeni). Oflaynda — "Narx tarixini ko'rish uchun internet kerak".
