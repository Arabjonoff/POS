# Shtrix-kod skaneri: sotuv va kirim

## Qo'llab-quvvatlanadigan qurilmalar
1. **USB/Bluetooth HID skaner** (klaviatura emulyatsiyasi) — Windows va Android. Eng ko'p ishlatiladigan tur. Skaner belgilarni juda tez "yozadi" va oxirida Enter yuboradi.
2. **Telefon kamerasi** — Android/iOS (`mobile_scanner` paketi). Skaner yo'q do'konlar uchun.
3. **Android terminallarining ichki skaneri** (Sunmi va h.k.) — odatda HID rejimida ishlaydi; maxsus SDK keyinroq.

## HID kiritishni aniqlash (`BarcodeScannerService`)
- Global klaviatura tinglovchisi (`HardwareKeyboard.instance.addHandler`), fokus qayerda bo'lishidan qat'i nazar.
- Qoida: belgilar orasidagi interval ≤ **35 ms**, uzunlik ≥ **4**, oxiri Enter (yoki Tab) → bu **shtrix-kod hodisasi**. Sozlamalarda interval va tugash belgisi o'zgartiriladi.
- Shtrix-kod hodisasi aniqlansa, o'sha belgilar fokusdagi matn maydoniga tushmasligi kerak (bufer, keyin qaror). Sekin yozilgan matn (inson) — oddiy kiritish sifatida o'tadi.
- Hodisa: `Stream<ScanEvent>` — `{code, source: hid|camera, at}`.
- Har ekran o'z ishlovchisini ro'yxatdan o'tkazadi (stack): kassa, kirim, inventarizatsiya, tovar kartasi. Faqat eng yuqoridagi ekran hodisani oladi.
- Kirish signali: muvaffaqiyat — qisqa "bip" + yashil chaqnash; topilmadi — boshqa ovoz + sariq xabar. Ovozni o'chirish sozlamasi.

## Kod formatlari va tekshiruv
- EAN-13, EAN-8, UPC-A, UPC-E, Code128, Code39, ITF-14, QR (keyinroq markirovka uchun).
- EAN/UPC uchun nazorat raqami tekshiriladi; noto'g'ri bo'lsa "Kod noto'g'ri o'qildi, qayta skanerlang".
- Bosh/oxirgi bo'shliqlar olib tashlanadi; boshidagi nollar saqlanadi (kod — matn, son emas).

## Vaznli (tarozi) shtrix-kodlari
- Tarozi chop etgan EAN-13: `PP CCCCC WWWWW K` — `PP` prefiks (sozlanadi, default `20–29`), `CCCCC` — tovar PLU kodi, `WWWWW` — vazn grammda (yoki narx — sozlamada tanlanadi), `K` — nazorat.
- Format sozlamalarda: prefikslar, PLU uzunligi (5), qiymat turi (vazn/narx), kasr (3).
- Tahlil natijasi: `Product(plu_code)` + `qty_milli` (gramm = milli-kg).

## Sotuv ekranida xatti-harakat
1. Kod → `ProductBarcode` qidiruvi (lokal SQLite, indeks). Vaznli kod bo'lsa — PLU bo'yicha.
2. Topildi → savatga qo'shiladi; savatda shu tovar bo'lsa miqdor +1 (vaznli — yangi qator). Qator qisqa yonib-o'chadi, ro'yxat unga aylanadi.
3. Topilmadi → sariq xabar: "Bu kod bazada yo'q" + tugmalar: **"Tovar qo'shish"** (huquqi borlarga; shtrix-kod to'ldirilgan tez forma: nom, narx, birlik → saqlash → savatga qo'shiladi) va **"Bekor"**.
4. Tovar nofaol yoki narxi 0 → ogohlantirish, savatga qo'shilmaydi.
5. To'lov oynasi ochiq paytda skanerlash → oyna yopilmaydi, hodisa e'tiborsiz qoldiriladi va qisqa xabar: "Avval to'lovni yakunlang".

## Kirim ekranida xatti-harakat
1. Kod → topildi: kirim qatoriga qo'shiladi yoki miqdor +1. Qatorda oxirgi tannarx va sotish narxi oldindan to'ldiriladi.
2. Topilmadi → yangi tovar formasi (shtrix-kod to'ldirilgan; nom, kategoriya, birlik, tannarx, sotish narxi). Saqlangach kirimga qo'shiladi.
3. Bir xil kodni ketma-ket skanerlash — miqdorni oshiradi (har skanerda +1); miqdorni raqam bilan ham kiritish mumkin.

## Inventarizatsiya va tovar kartasi
- Inventarizatsiya: skanerlash → sanalgan miqdor +1.
- Tovar kartasi: shtrix-kod maydonida skanerlash → kod qo'shiladi; boshqa tovarda bor bo'lsa — qaysi tovar ekanini ko'rsatib ogohlantirish.

## Testlar
- Simulyatsiya: 13 belgi 10 ms oraliqda + Enter → 1 ta `ScanEvent`.
- 13 belgi 150 ms oraliqda → oddiy matn.
- Vaznli kod `2012345012503` → PLU `12345`, 1,250 kg.
- Nazorat raqami noto'g'ri EAN-13 rad etiladi.
- Kirim: bir kod 5 marta → bitta qator, miqdor 5.
