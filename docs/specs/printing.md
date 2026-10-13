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
