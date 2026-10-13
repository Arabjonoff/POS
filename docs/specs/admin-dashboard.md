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
