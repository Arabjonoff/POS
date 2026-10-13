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
