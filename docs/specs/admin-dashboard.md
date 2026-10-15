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
