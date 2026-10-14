# 0007. Kassada vaqt zonasi — qat'iy siljish (UTC+5)
- Sana: 2026-10-14 · Holat: qabul qilingan

**Qaror.** Kassa ilovasi sana/vaqtni do'kon vaqt zonasida (`Tenant.timezone`) ko'rsatadi, lekin to'liq IANA bazasi (`timezone` paketi) o'rniga `StoreTimeZone` enum'i ishlatiladi: `Asia/Tashkent`, `Asia/Samarkand` — ikkalasi UTC+5. Noma'lum nom — Toshkent.

**Nima uchun.** O'zbekistonda 1992 yildan beri yozgi vaqt yo'q, mamlakat bitta siljishda. IANA bazasi ilova hajmini ~0,5–1 MB oshiradi va ishga tushishda yuklanishi kerak — bitta siljish uchun keraksiz. Qurilma soati/zonasi noto'g'ri sozlangan bo'lishi mumkin (mahalla do'konlarida tez-tez), shuning uchun qurilma mahalliy zonasiga tayanmaymiz: vaqt UTC'da saqlanadi, ekranga `wallClock = utc + 5 soat` chiqadi.

**Oqibat.** Boshqa mamlakatga chiqilsa — `timezone` paketiga o'tish va `StoreTimeZone` ni almashtirish kerak bo'ladi (bitta joy: `apps/pos/lib/core/time/store_time_zone.dart`). Server tomoni (Django) to'liq IANA bilan ishlaydi — o'zgarmaydi.
