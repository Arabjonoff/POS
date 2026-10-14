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

## API (T-011)
- `POST /api/v1/auth/login/` `{phone, password}` → `{access, refresh, user}`. Telefon istalgan ko'rinishda (`90 123 45 67`) — serverda normallashtiriladi. Xato: `401 invalid_credentials` (telefon/parol noto'g'ri, parolsiz foydalanuvchi, nofaol).
- `POST /api/v1/auth/refresh/` `{refresh}` → `{access, refresh}` (rotatsiya). Nofaol foydalanuvchi — `401`.
- `GET /api/v1/auth/me/` → `{id, phone, full_name, role, tenant: {id, name} | null}`.
- `GET /api/v1/users/`, `/users/{id}/` — o'z tenanti xodimlari (manager va owner). Boshqa tenant foydalanuvchisi — `404`.
- Login va refresh — throttle (`auth`: 20/daqiqa IP bo'yicha).
- Model va PIN formati: `docs/decisions/0006-users-pin.md`.

## Kassada PIN bilan kirish (T-034)
- Qulf ekrani (`/lock`): faol xodimlar (pull'dan, `staff_users`) kartalari; PIN'i yo'q xodim — o'chiq ("PIN o'rnatilmagan"). PIN 4–6 raqam: ekran klaviaturasi yoki fizik klaviatura (raqamlar, numpad, Backspace), tasdiqlash — ✓ yoki Enter; Esc — boshqa xodim.
- Tekshiruv oflayn (`PinHash`, PBKDF2-SHA256, alohida isolate'da), `testdata/pin_hash.json` vektorlari bilan server bilan bir xil.
- **5 marta xato → 1 daqiqa kutish** (teskari sanoq ko'rinadi); hisoblagich va kutish muddati `LocalSettings` da — ilovani qayta ochish chetlab o'tmaydi. To'g'ri PIN hisoblagichni nolga tushiradi.
- **Avtomatik qulflash**: ekranga tegish/tugma (skaner ham) bo'lmasa — sozlamadagi vaqtdan keyin (O'chiq, 2, 5 (standart), 10, 30 daqiqa). Qo'lda: yon paneldagi qulf tugmasi yoki Sozlamalar → "Qulflash".
- PIN'dan keyin darhol kassa ekrani.
