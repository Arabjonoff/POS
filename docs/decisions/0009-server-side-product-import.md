# 0009. Tovar importi — serverda
- Sana: 2026-10-15 · Holat: qabul qilingan

**Qaror.** Excel/CSV import (T-051) serverda bajariladi. Kassa faylni qurilma tokeni bilan yuklaydi (`/api/v1/sync/product-imports/`); server faylni o'qiydi, moslashni taklif qiladi, tekshiradi va to'g'ri qatorlarni bitta tranzaksiyada qo'llaydi (tovarlar, shtrix-kodlar, yangi kategoriyalar, narx tarixi, boshlang'ich qoldiq uchun kirim). Natija kassaga oddiy pull orqali keladi. Import uchun internet kerak.

**Nima uchun.**
- ROADMAP: "server tomonda katta fayllar uchun".
- Kassada kategoriya yaratish hodisasi yo'q, import esa yangi kategoriyalarni yaratishi kerak. Boshlang'ich qoldiq server kirimi bilan yoziladi.
- 5000 qatorni outbox orqali 5000 ta `product.upserted` hodisasiga aylantirish 50 ta push va 5000 ta alohida tekshiruv bo'lardi. Qisman rad etishda kassa va server bir-biridan farq qilib qolardi.
- Xlsx o'qish (`openpyxl`) serverda bitta joyda bo'ladi; Dart'da Excel kutubxonasi kerak emas.
- Import — kamdan-kam, odatda boshlang'ich sozlashda bajariladigan amal; oflayn talab qilinmaydi.

**Oqibat.** Oflaynda import yo'q ("Import uchun internet kerak"). Fayl serverda 24 soat saqlanadi (keyin o'chiriladi). Kim import qilgani (`by`) — kassadagi menejer/ega PIN bilan, `product.upserted` bilan bir xil ishonch modeli.
