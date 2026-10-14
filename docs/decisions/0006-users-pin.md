# 0006. Foydalanuvchi modeli va PIN hash formati
- Sana: 2026-10-14 · Holat: qabul qilingan

**User.** O'z modelimiz `accounts.User` (`AUTH_USER_MODEL`), UUIDv7 id. Kirish maydoni — telefon (`+998XXXXXXXXX`, global unique).
- Rollar: `platform_admin`, `owner`, `manager`, `cashier`. `tenant` faqat `platform_admin` da bo'sh (DB constraint).
- Parol faqat `platform_admin`, `owner`, `manager` da (telefon + parol bilan kirish). Kassirda parol yo'q — faqat PIN.
- Telefon `owner`, `manager`, `platform_admin` uchun majburiy; kassir uchun ixtiyoriy (bir odam ikki do'konda ishlasa ham to'qnashuv bo'lmasin).
- Django admin'ga faqat `platform_admin` kiradi (`is_staff` = rol).

**PIN hash.** Kassada oflayn tekshiriladi (Dart), shuning uchun format oddiy va ikkala tomonda bir xil:
`pbkdf2_sha256$120000$<salt>$<base64(sha256-PBKDF2(pin, salt, 120000, 32 bayt))>` — Django `PBKDF2PasswordHasher` formati, iteratsiya 120 000 (spec: ≥ 100 000; Django'ning 1 000 000 tasi arzon Android'da bir necha soniya oladi).
- PIN — 4–6 raqam. Tuz har PIN uchun tasodifiy.
- Umumiy test vektorlari: `testdata/pin_hash.json` (Python va Dart bir xil vektorlardan o'tadi).
- Server PIN'ni `apps.accounts.pins` orqali tekshiradi (`PASSWORD_HASHERS` ga bog'liq emas).

**Token.** SimpleJWT: access 30 daqiqa, refresh 30 kun, rotatsiya yoqilgan. Login, refresh — `ScopedRateThrottle` (`auth`).
