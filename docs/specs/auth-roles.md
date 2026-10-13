# Autentifikatsiya va rollar

| Rol | Qayerda | Huquqlar |
|---|---|---|
| platform_admin | Admin dashboard | Hamma tenantlar, tariflar, obunalar, qurilmalar |
| owner | Kassa ilovasi | Hammasi o'z tenanti ichida: xodimlar, sozlamalar, narx, kirim, hisobotlar, qarz tuzatish |
| manager | Kassa ilovasi | Savdo, kirim, inventarizatsiya, tovarlar, qaytarish tasdiqlash, hisobotlar (sozlamaga ko'ra) |
| cashier | Kassa ilovasi | Savdo, nasiyaga sotish (limit ichida), qarz to'lovi qabul qilish, o'z smenasi |

- Ilovaga birinchi kirish: owner telefon + parol → JWT → qurilma ro'yxatdan o'tadi → uzoq muddatli qurilma tokeni (refresh) xavfsiz saqlanadi (`flutter_secure_storage`).
- Kundalik kirish: kassir tanlash + PIN (4–6 raqam). PIN hash'lari pull orqali keladi, tekshiruv lokal (oflaynda ham). Hash: argon2id yoki PBKDF2 (≥ 100 000 iteratsiya) + tuz.
- Huquq talab qiluvchi amal (narx o'zgartirish, qaytarish, katta chegirma, limitdan oshish) → menejer/ega PIN oynasi, amalda kim tasdiqlagani yoziladi.
- Admin dashboard: platform_admin login, JWT httpOnly cookie, 2FA keyinroq.
