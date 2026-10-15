# 0008. Chek printeriga ulanish — tarmoq va Windows spooler, Android Bluetooth/USB keyin
- Sana: 2026-10-15 · Holat: qabul qilingan

**Qaror.** T-044 da printerga ikki yo'l bilan ulaniladi:
1. **Tarmoq (IP:9100, RAW)** — `dart:io` `Socket`, barcha platformalarda (Windows, Android, iOS).
2. **Windows spooler** — tizimga o'rnatilgan printer (USB printer ham shu orqali), `winspool.drv` ga o'z `dart:ffi` bog'lamalarimiz (8 ta funksiya) bilan RAW hujjat. Tashqi plagin yo'q, faqat `ffi` paketi.

Android Bluetooth (SPP) va USB alohida vazifa bo'ldi: **T-047**. Chek matni (`ReceiptBuilder`) va ESC/POS kodlovchi (`EscPos`) uzatish qatlamidan ajratilgan, shuning uchun yangi ulanish faqat `PrinterTransport` ning yangi turini qo'shadi.

**Nima uchun.** Bluetooth/USB uchun native plagin tanlash kerak (ruxsatlar, Android 12+ `BLUETOOTH_CONNECT`, USB host). Ularni haqiqiy qurilma va printersiz sinab bo'lmaydi, CI esa Windows'da ishlaydi. Tarmoq va Windows yo'llari unit va widget testlarida (soxta transport, lokal `ServerSocket`, haqiqiy `EnumPrinters`) to'liq tekshiriladi. `win32` 6.x ning API'si katta va tez o'zgaradi — kerakli 8 funksiyani o'zimiz bog'lash barqarorroq.

**Oqibat.** Android kassalarda hozircha faqat Wi-Fi/LAN printer ishlaydi. Printer bo'lmasa yoki xato bersa ham savdo to'xtamaydi: chek fonda chiqariladi, xato bo'lsa "Chek chiqmadi" xabari va "Qayta chop etish" tugmasi chiqadi. CP866 da yo'q o'zbek kirill harflari (ў қ ғ ҳ) chekda у к г х bo'lib chiqadi. To'liq kirill kerak bo'lsa, sozlamada UTF-8 tanlanadi (printer qo'llasa).

**Yangilanish (T-047, 2026-10-15).** Android Bluetooth (SPP) va USB host ham **tashqi plaginsiz** qo'shildi: o'z `MethodChannel`imiz va
`PrinterChannel.kt` (~300 qator Kotlin). Faqat juftlangan Bluetooth qurilmalar ishlatiladi (qidiruv va joylashuv ruxsati kerak emas).
Soxta kanal bilan testlangan, haqiqiy printerda — `docs/printing-android-checklist.md` (Q-007). Sunmi kabi ichki printerlar — keyin.
