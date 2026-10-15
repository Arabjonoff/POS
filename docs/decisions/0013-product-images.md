# 0013. Mahsulot rasmlari — alohida navbat, o'zgarmas obyekt, tenant tekshiruvi

- Holat: qabul qilingan (2026-10-15, T-105)
- Kontekst: loyiha egasi mahsulotga rasm qo'shish, almashtirish, olib tashlash, ro'yxatda kichik va kartada katta ko'rinishni talab qildi;
  rasm sahifa yangilanganda yo'qolmasin. Kassa oflayn ishlaydi; outbox — JSON.

## Qaror
1. Rasm **o'zgarmas obyekt** (kassa id'si); almashtirish — yangi id. Fayl/URL abadiy keshlanadi.
2. Baytlar **JSON outbox'dan o'tmaydi** — alohida navbat (`product_images`) va multipart endpoint. Rasm xatosi savdo/kirim sinxronini
   hech qachon to'xtatmaydi.
3. **Tovar rasmini kutmaydi:** `product.upserted` rasmga tegmaydi; rasm endpoint'i tovarga biriktiradi (`409 product_missing` — kassa kutadi).
4. Kassa rasmni JPEG 800 px ga keltiradi (`image` paketi, isolate'da); server Pillow bilan qayta tekshiradi va kodlaydi (EXIF yo'q).
5. Fayllar ochiq URL orqali berilmaydi — qurilma/tenant tekshiruvi bilan view (4-qoida).
6. Windows uchun `cached_network_image`/sqflite ishlatilmaydi: o'z fayl keshimiz (ilova papkasi + drift jadvali).

## Oqibatlar
- Zaxira nusxaga rasmlar arxivi qo'shildi.
- Kamera orqali suratga olish (Android/iOS) — keyinroq (`image_picker`).
