# Admin dashboard (Next.js) — SaaS egasi uchun

Foydalanuvchi: platforma egasi (siz) va yordamchi adminlar. Do'kon egalari bu panelni ishlatmaydi.

## Texnologiya
Next.js App Router, TypeScript (strict), Tailwind, shadcn/ui, TanStack Query + Table, react-hook-form + zod, Recharts (grafiklar), next-intl (uz, ru), Playwright + Vitest. API — `openapi-fetch` (Django OpenAPI'dan tiplar). Auth: Next route handler Django JWT'ni httpOnly cookie'da saqlaydi; middleware himoyalangan yo'llarni tekshiradi.

## Sahifalar
1. **Kirish** — telefon/parol.
2. **Bosh sahifa** — KPI kartalari: faol mijozlar, sinovdagilar, MRR, shu oy tushum, muddati 7 kunda tugaydiganlar (ro'yxat, "To'lov kiritish" tugmasi bilan), uzoq vaqt sinxronlanmagan qurilmalar; oylik tushum grafigi.
3. **Mijozlar** — jadval: do'kon, ega, telefon, tarif, holat (rangli badge), to'langan muddat, qurilmalar soni, oxirgi faollik. Qidiruv, holat filtri, saralash, CSV eksport.
4. **Yangi mijoz** — 3 qadamli usta: do'kon ma'lumotlari → ega (telefon, ism, vaqtinchalik parol generatsiya) → tarif va sinov muddati. Oxirida: kirish ma'lumotlari ko'chirib olish uchun karta.
5. **Mijoz sahifasi** — tablar: Umumiy (obuna holati, tugash sanasi, tez amallar: to'lov kiritish, uzaytirish, bloklash), To'lovlar, Qurilmalar (bloklash), Foydalanuvchilar (parolni tiklash), Faollik (sinxron statistikasi, rad etilgan hodisalar).
6. **Tariflar** — CRUD, faol/nofaol.
7. **To'lovlar** — barcha to'lovlar, davr filtri, jami, CSV.
8. **Qurilmalar** — barcha qurilmalar, versiya, oxirgi sinxron, bloklash.
9. **Audit jurnali** — kim, nima, qachon, oldin/keyin.
10. **Sozlamalar** — adminlar ro'yxati, default sinov muddati, grace/oflayn kunlari.

## UI/UX
- Toza, zamonaviy, ma'lumot zich lekin havodor; yorug'/qorong'i; 1280 px va undan katta ekran asosiy, planshetda ham ishlaydi.
- Har jadvalda: bo'sh holat, yuklanish skeletoni, xato holati, sahifalash.
- Xavfli amallar (bloklash, to'lovni bekor qilish) — tasdiqlash oynasi, sabab maydoni.
- Har amal audit jurnaliga yoziladi.

## Kirish va sessiya (T-080)
- `/login` — telefon + parol (qobiqsiz sahifa, til va mavzu tugmalari bilan). Xatolar oddiy tilda: noto'g'ri telefon/parol, "Bu hisob admin paneli uchun emas" (owner/manager), urinishlar ko'p (429), server javob bermadi.
- `POST /api/auth/login` (Next route handler) → Django `POST /api/v1/auth/login/`; faqat `role = platform_admin`. JWT'lar httpOnly cookie'larda: `pos_access` (29 daqiqa), `pos_refresh` (30 kun), `SameSite=Lax`, production'da `Secure` (`COOKIE_INSECURE=1` — faqat HTTP sinov muhiti uchun). Brauzer JavaScript'i tokenni ko'rmaydi.
- `POST /api/auth/logout` — cookie'larni o'chiradi.
- `src/proxy.ts` (Next 16 "Proxy", sobiq middleware): cookie yo'q — `/login?next=<yo'l>`; access eskirgan, refresh bor — Django'da yangilaydi (rotatsiya) va shu so'rovning o'ziga ham yangi token beradi; refresh yaroqsiz — cookie'lar o'chadi. Faqat optimistik tekshiruv.
- Haqiqiy tekshiruv — `(app)/layout.tsx` dagi `getCurrentAdmin()` (Django `auth/me/`, rol `platform_admin`); aks holda `/login`. `next` faqat ichki yo'l (`safeNext`).
- Django manzili serverda: `API_URL_INTERNAL` (Docker: `http://backend:8000`), bo'lmasa `NEXT_PUBLIC_API_URL`.
- Qobiq: chapda menyu (planshet/telefonda — sheet), tepada til, mavzu, admin ismi va "Chiqish". Hali qurilmagan bo'limlar — "Bo'lim tayyorlanmoqda" (`(app)/[section]`).
- E2E: `e2e/mock-api.mjs` — soxta Django auth API (Playwright `webServer`), haqiqiy backend kerak emas.

## Bosh sahifa (T-081)
- Ma'lumot: `GET /api/v1/platform/stats/` (server komponent, admin access tokeni bilan; `401` → `/login`, boshqa xato → "Ma'lumotni yuklab bo'lmadi" + "Qayta urinish"). Yuklanishda — kartalar shaklidagi skelet.
- KPI kartalari: **Faol mijozlar** (`active`; ostida jami, muddati o'tgan, faqat o'qish, bloklangan), **Sinovdagilar**, **Oylik tushum (MRR)**, **Shu oy to'lovlar**. Pul — tiyindan `1 350 000 so'm` (`src/lib/format.ts`, butun son).
- **Oylik tushum** grafigi (Recharts, ustunlar): oxirgi 12 oy, oy nomi tilga qarab (`noy, 25` / `нояб. 25`), tooltip — summa.
- **Muddati 7 kunda tugaydi**: nom (mijoz sahifasiga havola), "… gacha to'langan", qolgan kun (≤ 2 — qizil), **To'lov kiritish** → `/tenants/{id}?payment=1` (to'lov oynasi — T-083).
- **Sinxronlanmagan qurilmalar** (3 kundan ortiq) soni → `/devices?stale_days=3`.
- Joylashuv: desktop (≥ 1280) — 4 KPI, grafik + o'ngda ro'yxatlar; planshet — 2×2 KPI, grafik to'liq kenglikda, ostida ikki karta; telefon — bir ustun.

## Mijozlar (T-082)
- **Ro'yxat** `/tenants`: jadval (do'kon, ega + telefon, tarif, holat badge'i, muddat — sinovda `trial_ends_at`, aks holda `paid_until`, qurilmalar, oxirgi faollik). Qidiruv (nom/telefon, 300 ms kutib) va holat filtri URL'da (`?search=&status=`), sahifalash 25 tadan, bo'sh holat ("Hali mijoz yo'q" / "Hech narsa topilmadi"), **CSV** — joriy sahifa (UTF-8 BOM, Excel ochadi). Saralash — keyinroq (API'da `ordering` yo'q).
- **Yangi mijoz** `/tenants/new` — 3 qadam: do'kon (nom*, manzil, izoh) → ega (telefon*, ism*, parol: vaqtinchalik yaratilsin yoki o'zi kiritadi ≥ 8 belgi) → tarif (faqat faol, oylik narxi bilan) va sinov kunlari (0–90, standart 14). Har qadam o'zi tekshiriladi; band telefon (`409 phone_taken`) — 2-qadamga qaytadi. Natija kartasi: do'kon, telefon, parol (faqat shu yerda), "Nusxa olish", "Mijoz sahifasi", "Yana qo'shish".
- **Mijoz sahifasi** `/tenants/{id}` — tablar URL'da (`?tab=`): Umumiy (obuna: holat, tarif, sinov tugashi, to'langan muddat, qolgan/imtiyozli/oflayn kunlar; do'kon ma'lumotlari), To'lovlar (jadval + jami netto), Qurilmalar, Foydalanuvchilar (ega/menejer uchun "Parolni tiklash" — tasdiqlash, yangi vaqtinchalik parol bir marta ko'rinadi; kassirda yo'q — PIN), Faollik (sinxron hodisalari). Bloklash — sabab majburiy, tasdiqlash oynasi; bloklangan mijozda qizil banner + sabab; blokdan chiqarish — izoh ixtiyoriy.
- O'zgarishlar Server Actions orqali (`(app)/tenants/actions.ts`), Django audit jurnaliga yozadi (T-020).
- Vaqt — Toshkent bo'yicha `dd.mm.yyyy HH:mm` (`formatDateTime`).

## Tariflar, to'lovlar (T-083)
- **Tariflar** `/plans`: jadval (nomi, oylik narx, qurilmalar/xodimlar cheklovi, obunachilar, holat). Yaratish/tahrirlash oynasi — narx so'mda matn (`99 000`, `1 250,50`) → tiyin butun son (`parseSom`, `float` yo'q). "Nofaol qilish" — tasdiqlash bilan (`DELETE` = `is_active=false`); nofaol tarif yangi mijoz ustasida ko'rinmaydi, obunalar saqlanadi. Planshetda amallar ikonka (nomi `aria-label`da).
- **To'lov kiritish** (mijoz sahifasi sarlavhasida; bosh sahifadagi "To'lov kiritish" → `?payment=1` darhol ochadi): oylar (1/3/6/12 tugmalari yoki 1–36), summa = tarif × oy (admin o'zgartirmaguncha avtomatik), usul (naqd/o'tkazma/karta/boshqa), izoh; **yangi davr oldindan ko'rinadi** — serverdagi formula (`src/lib/billing.ts`: `period_from = max(paid_until, trial_ends_at, bugun Toshkent)`, `+ oylar`, oy oxiri qisqartiriladi). Saqlangach — "To'lovlar" tabi.
- **Bekor qilish**: faqat oxirgi bekor qilinmagan to'lovda tugma; sabab majburiy; teskari yozuv (manfiy summa) qo'shiladi, asl qator "Bekor qilingan" (chizilgan), muddat oldingi holatiga qaytadi (server). Server `only_latest_payment` — tushunarli xabar.
- **To'lovlar** `/payments`: barcha mijozlar, sana oralig'i (`paid_at`, Toshkent; URL'da), mijozga havola, jami netto (bekor qilishlar bilan), sahifalash, CSV (summa so'mda, guruhlarsiz).
- Eslatma: Django `SIMPLE_JWT` refresh rotatsiyasi blacklist'siz — parallel so'rovlar (prefetch) bir xil refresh bilan kelsa ham sessiya uzilmaydi. Blacklist yoqilsa, proxy'da bir vaqtda bitta yangilash kerak bo'ladi.

## Qurilmalar va audit (T-084)
- **Qurilmalar** `/devices`: barcha kassalar (nomi + kodi, mijoz havolasi, platforma, versiya, oxirgi sinxron, holat). Filtr havolalari URL'da: Hammasi / **3 kundan beri sinxronlanmagan** (`?stale_days=3`, bosh sahifadagi havola shu) / Bloklangan (`?blocked=true`). 3 kundan eski yoki umuman sinxronlanmagan vaqt qizil. Bloklash — sabab majburiy (kassa sinxroni to'xtaydi), blokdan chiqarish — izoh ixtiyoriy; ikkalasi auditda. Mijoz/qurilma bloklash oynasi umumiy (`BlockDialog kind=tenant|device`).
- **Audit jurnali** `/audit`: yangisi birinchi; filtrlar — amal (15 ta, tarjimada) va obyekt turi (mijoz, obuna, to'lov, tarif, foydalanuvchi, qurilma), `?tenant=` (mijoz bo'yicha); ustunlar: vaqt (Toshkent), kim, amal, obyekt (+ "Mijoz sahifasi"), tafsilot — sabab va ochiladigan "N ta o'zgarish" (`before → after`, faqat o'zgargan maydonlar, `src/lib/audit.ts`). Sahifalash 25 tadan.
