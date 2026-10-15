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
- To'liq tavsif, API va qoidalar: `product-import.md` (qaror 0009 — serverda).
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
  - majburiy maydonlar (nom, sotish narxi) yorlig'ida qizil `*`; pul maydonlari guruhlanadi (`1 500 000,50`).
  - shu nomli boshqa faol tovar bo'lsa (qidiruv kaliti bo'yicha) — maydon ostida "«X» nomli tovar allaqachon bor. Shu tovarmi?" — **saqlashni to'xtatmaydi**.
  - ochilayotgan tovar bazada yo'q yoki serverda o'chirilgan bo'lsa — karta ochilmaydi, "Tovar topilmadi" (bo'sh "yangi" karta yangi tovar yaratib qo'ymasin).
- **Saqlash** — lokal baza (kassa katalogi darhol yangilanadi) + outbox `product.upserted` bitta tranzaksiyada. Server `by` ni faqat ega/menejerdan qabul qiladi: kassir saqlasa menejer/ega PIN so'raladi, menejer/ega o'zi bo'lsa PIN so'ralmaydi.
  Tahrirda hodisada **faqat o'zgargan maydonlar** (+ `id`, `by`) yuboriladi: oflayn eski tahrir serverdagi yangiroq narx/shtrix-kodni bosmaydi. Yangi tovar — to'liq.
- **Narx tarixi** (faqat menejer/ega, mavjud tovar): onlayn `GET /api/v1/sync/price-history/?product=` (qurilma tokeni). Oflaynda — "Narx tarixini ko'rish uchun internet kerak".

## Qoldiq tarixi va buyurtma ro'yxati (T-054)
- **Harakatlar tarixi** (tovar kartasida, hamma xodimlar uchun):
  - serverdagi harakatlar (barcha kassalar): `GET /api/v1/sync/stock-movements/?product=` (qurilma tokeni, oxirgi 100 ta, eng yangisi birinchi) — `{id, type, qty_milli, ref_type, at, created_by_name}`;
  - ustida hali yuborilmagan lokal harakatlar ("Yuborilmagan" belgisi bilan);
  - oflaynda — faqat lokal yuborilmaganlar va "To'liq tarix uchun internet kerak".
  - Turlari: kirim, savdo, qaytarish, tuzatish, inventarizatsiya. Miqdor ± birlik bilan.
- **Kam qolganlar**: Tovarlar → "Kam qolgan" filtri (faol, `min_stock > 0`, qoldiq ≤ min; hech qachon kirim qilinmaganlar ham). Shu filtrda **"Buyurtma ro'yxati"** tugmasi bor — CSV fayl (Excel ochadi: UTF-8 BOM, `;`).
  - Ustunlar: Nomi; Shtrix-kod; Qoldiq; Minimal qoldiq; Buyurtma; Tannarx; Summa.
  - **Buyurtma = 2 × minimal qoldiq − qoldiq** (minimal qoldiqning ikki baravariga yetkazish), dona tovarda butun songa yuqoriga yaxlitlanadi. Summa = buyurtma × tannarx (half-up).
