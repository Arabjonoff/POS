# Dizayn tizimi va UI/UX tamoyillari

## Tamoyillar
1. **Kassa birinchi.** PIN'dan keyin darhol kassa ekrani.
2. **3 harakatda savdo:** skaner → To'lash → to'lov turi.
3. **Katta nishonlar:** ≥ 48 dp, kassa asosiy tugmalari ≥ 56 dp, raqamli klaviatura tugmalari ≥ 64 dp.
4. **Bir qarashda tushunarli:** jami summa eng katta matn; qaytim — yashil, katta.
5. **Oddiy o'zbekcha:** "Internet yo'q — savdolar saqlanyapti (12)", "Sinxronizatsiya xatosi" emas.
6. **Xatoni tuzatish oson:** undo toast 5 s; xavfli amalda bitta tasdiq; ortiqcha modal yo'q.
7. **Holat doim ko'rinadi:** internet, printer, smena, navbat.
8. **Tezlik:** ≤ 100 ms javob, animatsiya ≤ 200 ms, skeleton yuklanishda.
9. **Kontrast:** WCAG AA; quyosh tushadigan do'konda o'qiladi; rang yolg'iz ma'no tashimaydi (ikon + matn).
10. **Klaviatura birinchi (Windows):** har asosiy amalning tezkor tugmasi, ekranda yorliq.
11. **Zamonaviy, lekin tinch:** toza tipografiya, yumshoq soyalar, bir xil radius, keraksiz bezaksiz.

## Tokenlar (boshlang'ich; agent Widgetbook'da sinab, yaxshilashi mumkin)
- Shrift: **Inter** (lotin + kirill), raqamlar uchun `tabular figures`.
- O'lchamlar: display 40/48 (jami summa), h1 28, h2 22, h3 18, body 16, small 14, caption 12. Telefonda kassa summasi 32.
- Oraliq: 4, 8, 12, 16, 24, 32, 48.
- Radius: 8 (input), 12 (tugma, karta), 16 (oyna), 999 (badge).
- Ranglar (yorug'): primary `#2563EB`, primary-hover `#1D4ED8`, success `#16A34A`, warning `#D97706`, danger `#DC2626`, background `#F8FAFC`, surface `#FFFFFF`, border `#E2E8F0`, text `#0F172A`, text-secondary `#475569`, muted `#94A3B8`.
- Ranglar (qorong'i): background `#0B1220`, surface `#111827`, border `#1F2937`, text `#F1F5F9`, text-secondary `#CBD5E1`, primary `#3B82F6`, success `#22C55E`, warning `#F59E0B`, danger `#EF4444`.
- Soyalar: 2 daraja (karta, oyna). Harakat: 120 ms (bosish), 200 ms (oyna).

## Breakpoint'lar
- compact < 600 (telefon), medium 600–899 (kichik planshet), expanded ≥ 900 (planshet/desktop), large ≥ 1280 (desktop).

## Komponentlar ro'yxati
Button, IconButton, TextField, SearchField, NumericKeypad, MoneyText, QtyStepper, Card, ListTile, Badge, StatusDot, AppDialog (desktop dialog / telefon bottom sheet), Toast (undo bilan), EmptyState, Skeleton, AppDataTable, ResponsiveScaffold, StatusBar, PinPad, ScanFeedback (yashil/sariq chaqnash).

## Tekshiruv (har ekran uchun)
- [ ] 3 o'lchamda golden test (telefon 390×844, planshet 1024×768, desktop 1440×900), yorug' va qorong'i
- [ ] bo'sh, yuklanish, xato holatlari bor
- [ ] barcha matnlar tarjima faylida, 3 tilda sig'adi (rus matni uzunroq)
- [ ] klaviatura bilan to'liq ishlatsa bo'ladi (desktop)
- [ ] asosiy amal ≤ 3 harakat
- [ ] kontrast AA
