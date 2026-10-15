# Chek chop etish (fiskal emas)

## Printerlar
- Termal ESC/POS, 58 mm (32 belgi) va 80 mm (48 belgi).
- Windows: tizimga o'rnatilgan printer (RAW rejimda ESC/POS yuborish) yoki tarmoq (IP:9100).
- Android: Bluetooth (SPP), USB, tarmoq.
- Sozlamalar: printer tanlash, kenglik, kodlash (CP866/UTF-8 + kirill/lotin sinovi), avtomatik chop etish, nusxalar soni, pul qutisini ochish, test chek.

## Chek shabloni
```
      <Do'kon nomi>
   <manzil, telefon>
--------------------------------
Chek: D3-000123   13.10.2026 20:15
Kassir: Aziza
--------------------------------
Non                1 x 4 000
                         4 000
Sut 1L             2 x 12 500
                        25 000
Kartoshka      1,250 kg x 6 000
                         7 500
--------------------------------
Chegirma                -1 500
JAMI                    35 000
Naqd                    50 000
Qaytim                  15 000
--------------------------------
   <pastki matn: Xaridingiz uchun rahmat!>
   Fiskal chek emas
```
- Nasiya bo'lsa: mijoz ismi va joriy qarz.
- Chek matnini generatsiya qilish — sof funksiya (`ReceiptBuilder`), snapshot testlar bilan; printer drayveri alohida qatlam.
- Printer xatosi savdoni bloklamaydi. "Oxirgi chekni qayta chop etish" har doim mavjud.

## Kassada amalga oshirilishi (T-044)
- **Chek matni** — `apps/pos/lib/features/printing/receipt.dart`: `ReceiptData` → `ReceiptBuilder(l10n, width)` → `ReceiptRow` lar (matn, qalin, markaz). Matn ilova tilida, belgilar ASCII bo'shliq/defis bilan. Uzun nom so'z bo'yicha o'raladi, "miqdor x narx" oxirgi qatorning o'ng chetida turadi. Qayta chop etilgan chekda "NUSXA" yoziladi. Snapshotlar: `apps/pos/test/printing/receipts/*.txt` (yangilash — `UPDATE_RECEIPTS=1`).
- **Ma'lumot** — `receipt_loader.dart`: do'kon (smena → `stores`: nom, manzil, telefon, sarlavha, pastki matn), kassir, qatorlar (birlik — tovardan), to'lovlar (naqd → karta → nasiya), nasiya mijozi va uning savdodan keyingi qarzi.
- **ESC/POS** — `escpos.dart`: `ESC @`, `ESC t 17` (CP866) yoki UTF-8, `ESC a` (markaz), `ESC E` (qalin), qog'oz surish + kesish `GS V 66 0`, pul qutisi `ESC p 0 25 250`. CP866 da yo'q o'zbek kirill harflari (ў қ ғ ҳ) у к г х bo'lib chiqadi.
- **Ulanish** — `printer_transport.dart`: tarmoq `IP[:port]` (standart 9100), Windows spooler (`winspool.dart`, RAW), Android Bluetooth/USB (T-047, pastda).
- **Sozlamalar** — har kassada o'zi (`local_settings`, kalit `printer`): ulanish, manzil yoki printer nomi, 58/80 mm, harflar jadvali, avtomatik chek, 1–3 nusxa, naqd to'lovda pul qutisi. Sozlamalar → Chek printeri sahifasida "Test chek" (chizg'ich, vaqt, lotin/kirill sinovi) va "Pul qutisini ochish" tugmalari bor.
- **Kassada** — yakunlangandan keyin chek fonda chiqadi, savdo uni kutmaydi. Xato bo'lsa "Chek yopildi · Qaytim … — chop etilmadi" xabari va "Qayta chop etish" (NUSXA) tugmasi chiqadi. Printer sozlangan bo'lsa, qidiruv qatorida "Oxirgi chek" tugmasi turadi.
- **Holat qatori** — sozlanmagan / tekshirilmoqda (ochilganda ulanish sinovi) / ulangan / ulanmagan; holat har chop etishdan keyin yangilanadi.

## Chek sifati va ko'rinishi (T-104a, audit `docs/audit/audit_printing.md`)
- **Bitta manba:** printer va ekrandagi **chek ko'rinishi** (`receipt_preview.dart`) bir xil `ReceiptRow` ro'yxatini ishlatadi —
  ustunlar, o'ralish, qalin/baland qatorlar farq qilmaydi. Ko'rinishda kodlash jadvalida yo'q harflar printerdagidek (`EscPos.printable`:
  CP866 da қ→к, umuman yo'q belgi — `?`). Qog'oz doim oq (`PosColors.receiptPaper`), shrift — Roboto Mono (`PosTypography.receipt`).
- **Sozlamalar → Chek ko'rinishi:** oxirgi savdo cheki, savdo bo'lmasa — namuna (uzun nom qo'shtirnoq bilan, vaznli tovar, qator
  chegirmasi, aralash to'lov va qaytim). "Test cheki" — sinov qismi (chizg'ich, lotin/kirill) + shu chek.
- **Kenglik:** 58 mm (32 belgi), 80 mm (48), 80 mm 42 belgi (512 nuqtali printerlar).
- **Qo'shimcha sozlamalar** (har kassada): kirill jadvali raqami `ESC t n` (standart 17), xitoycha rejimni o'chirish `FS .` (standart yoqiq —
  Xprinter kabi printerlarda kirill xitoycha chiqmasin), kesish (yo'q bo'lsa faqat suriladi), kesishdan oldingi bo'sh qatorlar (2–6).
- **Chek tarkibi:** bo'sh do'kon nomi/kassir qatori chiqmaydi; telefon `+998 71 200 00 00` ko'rinishida; donadan boshqa birlik har doim
  ko'rinadi (`250 g x 100`); chegirma bo'lsa avval **Summa**; **JAMI** — qalin va ikki barobar baland (`GS ! 1`); to'lovlar — chekka tushgan
  summa (yig'indisi = JAMI), so'ng **Berildi (naqd)** va **Qaytim**; nasiyada **Qarz (savdodan keyin)** — qayta chop etilsa ham o'sha savdo
  paytidagi qarz.
- **Belgilar:** `ʻ ʼ ‘ ’ ´` → `'`, `« » “ ”` → `"`, `…` → `...`, `×` → `x`, urg'uli lotin harflari → asosiy harf, boshqaruv belgilari
  va emoji olib tashlanadi; Ў/ў CP866 da o'z o'rnida (0xF6/0xF7).
- **Kassada:** chop etish xato bo'lsa "Qayta chop etish" o'sha chekni chiqaradi (NUSXA emas); avto-chek o'chiq bo'lsa ham naqd savdoda pul
  qutisi ochiladi (sozlamada yoqilgan bo'lsa); manzil har harfda emas, yozish to'xtagach saqlanadi.
- **Jismoniy printerda sinalmagan** (agent muhitida printer yo'q): baytlar unit testlarda, ko'rinish golden testlarda tekshirilgan.
  Birinchi o'rnatishda tekshirish: test cheki (Ў ў Қ Ғ Ҳ, oʻ gʻ, 48 belgili chizg'ich, kesish) — Xprinter 58/80, Epson, Windows, LAN.

## Chek rekvizitlari, ko'rsat/yashir, logotip (T-104b, qaror 0012)
- **Do'kon darajasi** (hamma kassada bir xil, serverda `Store`, pull orqali): nomi, **yuridik nomi**, **STIR (9) / JShShIR (14)**, manzil,
  telefon, chek sarlavhasi va pastki matni, **logotip** (kulrang PNG, ≤ 576×240, ≤ 96 KB), **ko'rsat/yashir** (`receipt_options`:
  logotip, yuridik nom, manzil, telefon, STIR, sarlavha, kassir, shtrix-kod, pastki matn; yo'q kalit — ko'rsatiladi).
- **Soliq raqami faqat kiritilsa** chiqadi, hech qachon taxmin qilinmaydi; yorlig'i uzunlikka qarab: 9 → "STIR", 14 → "JShShIR" (Q-011).
- **Muharrir:** Sozlamalar → "Chek rekvizitlari va ko'rinishi": chapda forma, o'ngda (telefonda pastda) **jonli** chek — saqlanmagan
  o'zgarishlar ham darhol ko'rinadi. Saqlash — ega/menejer (kassir — menejer PIN); lokal `stores` va `store.upserted` bitta tranzaksiyada;
  boshqa kassalar keyingi sinxronda oladi. Server `features` da `store_settings` bo'lmasa — forma o'chiq, izoh.
- **Logotip:** fayl (PNG/JPG) → kulrang, kichraytirilgan → PNG (server tekshiradi: PNG imzosi, hajm) → chop etishda printer kengligiga
  (58 mm — 384, 80 mm — 576 nuqta) 1 bitli rasm, `GS v 0`, 128 qatorli bo'laklar. Ko'rinishda — aynan o'sha nuqtalar.
- **Qurilma darajasi** (har kassada, `local_settings`): ulanish, kenglik, kodlash, kod sahifasi, `FS .`, kesish, surish, nusxalar, pul qutisi.

## Android: Bluetooth va USB printer (T-047, qaror 0008)
- **Dart:** `android_printer_channel.dart` — `MethodChannel('uz.zellypos.pos/printer')`; `AndroidPrinterTransport(kind, deviceId)`
  (`printer_transport.dart`). Sozlamada `connection`: `bluetooth` (manzil — MAC) yoki `usb` (manzil — `vendorId:productId`, qayta
  ulanganda o'zgarmaydi), `device_name` — ro'yxatda ko'rsatish uchun. Tanlov faqat Android'da ko'rinadi.
- **Native:** `android/app/src/main/kotlin/.../PrinterChannel.kt` (tashqi plagin yo'q). Usullar: `bluetoothDevices`, `bluetoothSend`,
  `bluetoothAvailable`, `usbDevices`, `usbSend`, `usbAvailable`. Xato kodlari: `bluetooth_off`, `permission_denied`, `not_found`, `io`.
  - Bluetooth: faqat **juftlangan** qurilmalar (qidiruv yo'q — `BLUETOOTH_SCAN`/joylashuv ruxsati kerak emas), printerlar (IMAGING)
    ro'yxat boshida. SPP UUID `00001101-…`, avval xavfsiz, bo'lmasa xavfsiz bo'lmagan RFCOMM. 1 KB bo'laklar; yopishdan oldin qisqa
    kutish (arzon printer buferi to'lib, chek oxiri yo'qolmasin). Android 12+ da `BLUETOOTH_CONNECT` birinchi murojaatda so'raladi.
  - USB: bulk OUT nuqtasi bor qurilmalar (printer sinfi 7 birinchi; HID skaner/klaviatura ro'yxatga tushmaydi). Ruxsat — tizim oynasi
    (`UsbManager.requestPermission`, PendingIntent MUTABLE + paket aniq). 16 KB bo'laklar, 5 s timeout.
  - Hamma yuborish bitta fon oqimida, ketma-ket (nusxalar aralashmaydi); javob asosiy oqimda.
- **Holat qatori:** "ulangan" — Bluetooth yoqiq va printer juftlangan / USB printer ulangan (ulanish ochilmaydi, tez).
- **Sozlamalar:** ro'yxat, tanlangan qurilma topilmasa ham ko'rinadi ("Hozir topilmadi — printerni yoqing yoki qayta ulang"); Bluetooth
  o'chiq / ruxsat yo'q / bo'sh ro'yxat — tushunarli xabar va "Ro'yxatni yangilash".
- **Savdo to'xtamaydi:** native xato `AndroidPrinterException` (Exception) → "Chek yopildi — chop etilmadi" + "Qayta chop etish".
- **Testlar:** soxta kanal (`test/helpers/fake_android_printer.dart`): `test/printing/android_printer_test.dart`,
  `test/features/android_printing_test.dart`, golden `printing/settings_bluetooth`. Kotlin `flutter build apk` bilan kompilyatsiya qilinadi.
- **Haqiqiy printerda sinalmagan** (agent muhitida Android qurilma va printer yo'q, Q-007): qo'lda sinov ro'yxati —
  `docs/printing-android-checklist.md`.
