# Kirim (tovar qabul qilish)

## Maqsad
Yetkazib beruvchidan kelgan tovarni skaner bilan tez qabul qilish va qoldiqni oshirish. Oflaynda ham ishlaydi.

## Oqim
1. "Kirim" → "Yangi kirim". Yetkazib beruvchi (ixtiyoriy, tez yaratish mumkin), sana, izoh.
2. Skanerlash (`barcode.md` → kirim xatti-harakati) yoki qidiruv bilan qatorlar qo'shish.
3. Har qator: tovar, miqdor, tannarx (oxirgisi oldindan), sotish narxi (oxirgisi; o'zgartirilsa narx yangilanadi), qator jami.
4. Pastda: qatorlar soni, jami tannarx.
5. "Saqlash" — qoralama (draft). "Tasdiqlash" — bitta tranzaksiya: StockReceipt(posted) + StockMovement(+) + Product narx yangilanishi + PriceHistory + OutboxEvent(`receipt.posted`).
6. Tasdiqlangan kirim o'zgartirilmaydi; xato bo'lsa "Teskari kirim" (qaytarish yetkazib beruvchiga) — manfiy harakat.

## Qoidalar
- Qoralama avtomatik saqlanadi (har o'zgarishda).
- Sotish narxi tannarxdan past bo'lsa — sariq ogohlantirish (bloklamaydi).
- Huquq: ega va menejer. Kassir — sozlamaga qarab.
- Desktop: qatorlar jadval ko'rinishida, Tab bilan miqdor → tannarx → narx; telefon: kartalar.

## Qabul mezonlari
- 100 ta ketma-ket skanerlash to'g'ri qatorlarga tushadi.
- Noma'lum kod → yangi tovar → kirimda paydo bo'ladi.
- Tasdiqlangandan keyin qoldiq ortadi (oflaynda ham), sinxrondan keyin serverda ham.

## Kassada amalga oshirilishi (T-052)
- **Bo'lim "Kirim"** (Ctrl+3) — `apps/pos/lib/features/receiving/`: ro'yxat (qoralamalar birinchi, keyin tasdiqlanganlar; sana, yetkazib beruvchi, qatorlar soni, jami tannarx, holat) va "Yangi kirim".
- **Qoralama** — `data/receipts/receipt_store.dart` (`ReceiptStore`): lokal `stock_receipts`/`stock_receipt_items`. Har o'zgarish darhol bazaga yoziladi — ekrandan chiqilsa yoki ilova yopilsa ham saqlanadi.
- **Skaner** (tahrirlovchida):
  - kod topildi → shu tovar qatoriga +1 (tarozi kodi — vazni bilan), yo'q bo'lsa yangi qator (oxirgi tannarx bilan);
  - noma'lum kod → tovar kartasi (kod to'ldirilgan), saqlangach kirimga qo'shiladi;
  - nazorat raqami xato → "Kod noto'g'ri o'qildi";
  - qo'lda yozilgan matn qidiruvga tushadi; natijadan bosib qo'shish mumkin.
- **Qator**: miqdor (birlik bilan, vaznli — kasr), tannarx, sotish narxi, qator jami. Narx tannarxdan past bo'lsa — sariq "Narx tannarxdan past" belgisi chiqadi (bloklamaydi). Narx hozirgisiga teng bo'lsa, o'zgarish yuborilmaydi (`new_sell_price_tiyin` yo'q).
- **Yetkazib beruvchi**: ro'yxatdan tanlash yoki tez yaratish (`supplier.upserted`, ega/menejer yoki PIN).
- **Tasdiqlash** — bitta tranzaksiya: holat `posted`, har qatorga `stock_movements` (+qty, `receipt`), tovar tannarxi (va berilgan bo'lsa sotish narxi) yangilanadi, outbox `receipt.posted` `{id, supplier, note, items: [{product, qty_milli, cost_price_tiyin, new_sell_price_tiyin?}], by}`.
  - Qoldiq kassada darhol oshadi (oflaynda ham).
  - Kassir bo'lsa menejer/ega PIN so'raladi.
  - Bo'sh kirimni tasdiqlab bo'lmaydi.
  - Tasdiqlangan kirim faqat o'qish uchun ochiladi; o'zgartirish — "Tuzatish" orqali (pastda).
  - Payloadda ixtiyoriy `at` (kassadagi vaqt) — server hujjat va harakat vaqtini shundan oladi.

## Tahrirlash va bekor qilish (T-102, qaror 0010)
Tasdiqlangan kirim **o'zgarmaydi** (CLAUDE.md 3-qoida). Tahrirlash = **tuzatish**: eski versiya teskari yozuv bilan bekor qilinadi va yangi
versiya kuchga kiradi — bitta tranzaksiyada, bitta outbox hodisasida.

- **Kirim kartasi** (tasdiqlangan, amaldagi versiya): "Tahrirlash" va "Bekor qilish". Server `features` da `receipt_corrections` ni e'lon
  qilmagan bo'lsa (eski server) — tugmalar o'rniga izoh.
- **Tahrirlash** → tuzatish qoralamasi (`corrects_id` = asl kirim): asl qatorlar nusxasi (bir tovar — bitta qator), yangi sotish narxisiz.
  Qoralama qoldiq va narxga ta'sir qilmaydi; "Tuzatishdan voz kechish" — o'chiradi. Banner: "Kirim tuzatilmoqda…".
- **Tuzatishni saqlash** → tasdiqlash oynasi: o'zgargan tovarlar `eski → yangi` va qoldiq manfiy bo'lsa ogohlantirish (bloklamaydi);
  keyin ruxsat (ega/menejer yoki menejer PIN). `ReceiptStore.postCorrection` bitta tranzaksiyada:
  1. teskari yozuv R (`reverses_id` = asl, qatorlar manfiy) va `stock_movements` (−qty);
  2. yangi versiya harakatlari (+qty), holat `posted`, hujjat sanasi — **asl kirimniki**;
  3. tannarx — faqat bu kirimdan keyin shu tovar bilan boshqa amaldagi kirim bo'lmasa (eski kirimni tuzatish yangi tannarxni bosmaydi);
     sotish narxi — tuzatishda kiritilgan bo'lsa;
  4. outbox `receipt.corrected {id, corrects, reversal_id, supplier, note, items, by, at}`.
  Qoldiq: **−eski + yangi** (10 → 7 = −10 + 7 = −3). Har harakat bir marta hisoblanadi: hammasi bitta hodisaga bog'langan va yuborilgach
  server qoldig'iga almashadi.
- **Bekor qilish** → tasdiqlash oynasi → ruxsat → teskari yozuv va `receipt.reversed {id, reverses, note, by, at}`. Narxlar o'zgarmaydi.
  Ochiq tuzatish qoralamasi o'chadi.
- **Ro'yxat:** teskari yozuvlar ko'rinmaydi; belgilar: "Qoralama", "Tuzatish qoralamasi", "Tasdiqlangan", "Tuzatish" (yangi versiya),
  "Tuzatilgan" (eski versiya, kartada "Yangi versiyani ochish"), "Bekor qilingan".
- **Server** (`correct_receipt`, `cancel_receipt`): asl kirim hali kelmagan — `pending`; takroriy — o'zgarishsiz. Ikki kassa bir kirimni
  oflayn tuzatsa — **rad etilmaydi**: oxirgi kelgan versiya amalda, `conflict = true` (ega ko'rib chiqadi). Bekor qilingan kirimni tuzatish ham
  shunday. Teskari yozuvni tuzatib/bekor qilib bo'lmaydi. Boshqa tenant kirimi — rad.
- Oldingi savdolarning tannarxi (`SaleItem.cost_tiyin`) qayta hisoblanmaydi — foyda hisobotlari o'zgarmaydi.
- Ochiq savollar: Q-010 (tahrirlash muddati, inventarizatsiyadan keyingi tuzatish, bekor qilishda tannarx).
