# ROADMAP — vazifalar ro'yxati

Belgilar: `[ ]` boshlanmagan · `[~]` jarayonda · `[x]` bajarildi · `[!]` to'xtadi (sabab `docs/QUESTIONS.md` da).
Har vazifa: **Maqsad**, **Bajarish**, **Qabul mezonlari**, **Bog'liq**. Vazifa faqat barcha qabul mezonlari bajarilib, CI yashil bo'lganda `[x]` bo'ladi.
Tartib: yuqoridan pastga. Bog'liqligi tayyor bo'lmagan vazifani o'tkazib, keyingisiga o't.

---

## 0-bosqich. Poydevor

### [x] T-001 Monorepo tuzilishi
- **Bajarish:** papkalar (`backend/`, `apps/pos/`, `apps/admin/`, `packages/ui/`, `packages/api_client_dart/`, `docs/`), `.gitignore`, `.editorconfig`, `Makefile` (asosiy buyruqlar), `.env.example`, `README.md` (o'zbekcha, ishga tushirish). Dart pub workspace (`pubspec.yaml` ildizda, `apps/pos` va `packages/*`).
- **Qabul:** `make help` buyruqlar ro'yxatini chiqaradi; CLAUDE.md'dagi "Buyruqlar" bo'limi haqiqiy buyruqlarga mos.
- **Bog'liq:** —

### [x] T-002 Docker Compose
- **Bajarish:** `postgres:16`, `redis:7`, `backend` (Django dev server), `admin` (Next.js dev). Volume'lar, healthcheck'lar. `docker-compose.prod.yml` keyinroq (T-090).
- **Qabul:** `docker compose up -d` dan keyin `http://localhost:8000/api/health/` → `{"status":"ok"}`, `http://localhost:3000` ochiladi.
- **Bog'liq:** T-001, T-003, T-005

### [x] T-003 Django skeleti
- **Bajarish:** `config/` (settings: base/dev/test/prod, `DATABASE_URL`), DRF, SimpleJWT, drf-spectacular (`/api/schema/`, `/api/docs/`), CORS, `apps/core` (UUIDv7 primary key, `TimeStampedModel`, `TenantScopedModel`, `TenantScopedViewSet`, umumiy pagination, xato formati), health endpoint, pytest + ruff sozlamalari.
- **Qabul:** `pytest` yashil; `ruff check` toza; `/api/docs/` ochiladi.
- **Bog'liq:** T-001

### [x] T-004 CI (GitHub Actions)
- **Bajarish:** 3 job: backend (postgres service, ruff, pytest), flutter (analyze, test, golden), admin (lint, typecheck, test, build). Faqat o'zgargan qism uchun ishlash (paths filter).
- **Qabul:** PR ochilganda 3 ta tekshiruv ko'rinadi va yashil.
- **Bog'liq:** T-003, T-005, T-006

### [x] T-005 Next.js admin skeleti
- **Bajarish:** `create-next-app` (TypeScript, App Router, Tailwind, ESLint), shadcn/ui, TanStack Query, Vitest, Playwright, `src/api/` (OpenAPI'dan generatsiya — `openapi-typescript` + `openapi-fetch`), bo'sh layout (sidebar + header), yorug'/qorong'i mavzu.
- **Qabul:** `npm run build` muvaffaqiyatli; Playwright smoke testi bosh sahifani ochadi.
- **Bog'liq:** T-001

### [x] T-006 Flutter skeleti
- **Bajarish:** `apps/pos` (platformalar: windows, android, ios), Riverpod, go_router, Drift, `flutter_localizations` + ARB (uz, uz_Cyrl, ru), `packages/ui` bo'sh paket, Widgetbook ilovasi (`packages/ui/widgetbook`). `analysis_options.yaml` qat'iy (very_good_analysis yoki flutter_lints + qo'shimcha).
- **Qabul:** `flutter analyze` toza; `flutter test` yashil; Windows'da `flutter run -d windows` bo'sh ilovani ochadi.
- **Bog'liq:** T-001

---

## 1-bosqich. Backend yadrosi
Spec'lar: `data-model.md`, `auth-roles.md`, `sync.md`, `subscription-billing.md`.

### [x] T-010 Tenant va Store
- **Bajarish:** `apps/tenants`: Tenant, Store modellari, admin ro'yxati. Tenant yaratilganda bitta Store avtomatik.
- **Qabul:** model testlari; tenant izolyatsiyasi testi uchun umumiy fixture.
- **Bog'liq:** T-003

### [x] T-011 Foydalanuvchilar va autentifikatsiya
- **Bajarish:** custom `User` (telefon bilan kirish), rollar (platform_admin, owner, manager, cashier), PIN (4–6 raqam, hash), `/api/v1/auth/login`, `/refresh`, `/me`. Permission klasslari rollar bo'yicha.
- **Qabul:** kirish/refresh testlari; kassir menejer endpointiga kira olmaydi; boshqa tenant foydalanuvchisini ko'ra olmaydi.
- **Bog'liq:** T-010

### [x] T-012 Qurilmalar (Device)
- **Bajarish:** ega login bilan kassa qurilmasini ro'yxatdan o'tkazadi (`POST /api/v1/devices/register`), qurilma uzoq muddatli token oladi. Tarifdagi `max_devices` chegarasi. Bloklangan qurilma 403.
- **Qabul:** chegara oshganda aniq xato; bloklangan qurilma sinxronlay olmaydi.
- **Bog'liq:** T-011, T-013

### [x] T-013 Tariflar va obuna
- **Bajarish:** Plan, Subscription, SubscriptionPayment; holat hisoblash funksiyasi (trial/active/grace/readonly/blocked) — `subscription-billing.md` bo'yicha; kunlik `manage.py update_subscriptions` buyrug'i.
- **Qabul:** sanalar bo'yicha holat o'tishlari uchun parametrlangan testlar (kamida 8 holat).
- **Bog'liq:** T-010

### [x] T-014 Katalog API
- **Bajarish:** Category, Unit, Product, ProductBarcode CRUD; shtrix-kod bo'yicha qidirish `GET /products/by-barcode/{code}`; bitta tenant ichida shtrix-kod takrorlanmasligi; vaznli tovar maydonlari (`is_weighted`, `plu_code`).
- **Qabul:** CRUD, takroriy shtrix-kod rad etiladi, izolyatsiya testi.
- **Bog'liq:** T-011

### [x] T-015 Ombor (StockMovement, kirim, inventarizatsiya)
- **Bajarish:** StockMovement (faqat qo'shiladi), StockReceipt + items, InventoryCount + items, qoldiq hisoblash (agregat + materialized `ProductStock` kesh jadvali).
- **Qabul:** kirim → qoldiq ortadi; inventarizatsiya farqni tuzatish harakati sifatida yozadi; qoldiq = harakatlar yig'indisi testi.
- **Bog'liq:** T-014

### [x] T-016 Mijozlar va nasiya
- **Bajarish:** Customer, DebtEntry; mijoz balansi; qarz limiti.
- **Qabul:** qarzga sotish va qisman to'lash balansni to'g'ri o'zgartiradi.
- **Bog'liq:** T-011

### [x] T-017 Savdo, smena, qaytarish
- **Bajarish:** Shift, Sale, SaleItem, SalePayment, Refund, CashMovement. Savdolar faqat sinxron push orqali keladi (kassadan), REST faqat o'qish uchun.
- **Qabul:** savdo yozilganda qoldiq harakati va (nasiya bo'lsa) qarz yozuvi yaratiladi; qaytarish teskari harakat yaratadi.
- **Bog'liq:** T-015, T-016

### [x] T-018 Sinxronlash API
- **Bajarish:** `sync.md` bo'yicha: `POST /api/v1/sync/push` (idempotent, paketli), `GET /api/v1/sync/pull?cursor=` (ChangeLog asosida), SyncEvent jurnali.
- **Qabul:** `sync.md` dagi barcha server qabul mezonlari testlarda (takroriy push, tartibsiz kelish, 2 qurilma bir tovarni sotishi).
- **Bog'liq:** T-012, T-017

### [x] T-019 Do'kon egasi hisobotlari API
- **Bajarish:** kunlik/oylik savdo, foyda, top tovarlar, kassir bo'yicha, qarzlar, kam qolgan tovarlar, manfiy qoldiq. `reports.md` bo'yicha.
- **Qabul:** test ma'lumotlari ustida hisobot raqamlari qo'lda hisoblangan qiymatlarga teng.
- **Bog'liq:** T-017

### [x] T-020 Platforma admin API
- **Bajarish:** `/api/v1/platform/...` (faqat platform_admin): tenantlar, tariflar, obunalar, to'lovlar, qurilmalar, statistika (faol mijozlar, MRR, muddati tugayotganlar), AdminAuditLog (har o'zgarish yoziladi).
- **Qabul:** tenant foydalanuvchisi 403 oladi; har o'zgarish audit jurnalida.
- **Bog'liq:** T-013, T-012

---

## 2-bosqich. Flutter poydevori
Spec'lar: `design-system.md`, `sync.md`, `i18n.md`.

### [ ] T-030 Dizayn tizimi (packages/ui)
- **Bajarish:** tokenlar (rang, tipografiya, oraliq, radius, soya, harakat), yorug'/qorong'i `ThemeData`, komponentlar: Button (primary/secondary/danger/ghost, s/m/l/xl), IconButton, TextField, SearchField, NumericKeypad, MoneyText, QtyStepper, Card, ListTile, Badge, StatusDot, Dialog/Sheet (telefonda bottom sheet, desktopda dialog), Toast, EmptyState, Skeleton, DataTable (desktop), ResponsiveScaffold (telefon/planshet/desktop breakpoint'lari).
- **Qabul:** har komponent Widgetbook'da barcha holatlari bilan; golden testlar yorug'/qorong'i va 3 o'lchamda; kontrast WCAG AA.
- **Bog'liq:** T-006

### [ ] T-031 Tarjimalar va formatlash
- **Bajarish:** ARB fayllar, til tanlash, summa formatlash (`125 000 so'm`), miqdor (`0,250 kg`), sana/vaqt (Asia/Tashkent).
- **Qabul:** formatlash unit testlari; kodda qattiq yozilgan matn yo'q (lint qoidasi yoki test).
- **Bog'liq:** T-006

### [ ] T-032 Lokal baza (Drift)
- **Bajarish:** `data-model.md` dagi do'kon qatlami jadvallari, OutboxEvent, SyncState; WAL va `synchronous=FULL`; migratsiya testlari.
- **Qabul:** sxema testlari; savdo yozish tranzaksiyasi atomarligi testi.
- **Bog'liq:** T-006

### [ ] T-033 Ilova qobig'i va navigatsiya
- **Bajarish:** go_router, ResponsiveScaffold: desktop/planshet — chapda navigatsiya paneli, telefon — pastki navigatsiya. Bo'limlar: Kassa, Tovarlar, Kirim, Mijozlar/Nasiya, Hisobotlar, Sozlamalar. Holat qatori.
- **Qabul:** 3 o'lchamda golden testlar; klaviatura bilan navigatsiya ishlaydi.
- **Bog'liq:** T-030, T-031

### [ ] T-034 Kirish, qurilmani ulash, PIN ekrani
- **Bajarish:** birinchi ishga tushishda: ega telefon+parol → qurilma nomi → birinchi sinxron (progress bilan). Keyin har safar: kassir tanlash + PIN (katta raqamli klaviatura). Avtomatik qulflash (sozlanadigan).
- **Qabul:** oflaynda PIN bilan kirish ishlaydi; noto'g'ri PIN 5 marta — 1 daqiqa kutish.
- **Bog'liq:** T-032, T-033, T-011

### [ ] T-035 Sinxronlash dvigateli
- **Bajarish:** outbox push (fon, eksponensial kutish), pull (cursor), ulanish holatini kuzatish, holat qatorida "N ta yozuv navbatda". Obuna holatini saqlash va `readonly` rejim.
- **Qabul:** `sync.md` klient qabul mezonlari integration testlarda (soxta server bilan).
- **Bog'liq:** T-032, T-018

---

## 3-bosqich. Kassa
Spec'lar: `barcode.md`, `pos-screen.md`, `printing.md`, `shifts.md`.

### [ ] T-040 Skaner xizmati
- **Bajarish:** `barcode.md` bo'yicha: HID (klaviatura emulyatsiyasi) skanerni tez kiritish oqimidan ajratish, Android'da kamera skaneri (`mobile_scanner`), vaznli shtrix-kodlarni tahlil qilish, ovoz/vibratsiya signali.
- **Qabul:** unit testlar: tez kiritish → shtrix-kod hodisasi; sekin qo'lda yozish → oddiy matn; vaznli EAN-13 to'g'ri ajratiladi; EAN-13/EAN-8/UPC nazorat raqami tekshiriladi.
- **Bog'liq:** T-006

### [ ] T-041 Smena ochish/yopish
- **Bajarish:** smena ochilmaguncha savdo yo'q; ochishda boshlang'ich naqd; yopishda sanalgan naqd, farq, X/Z hisobot (ekran + chek).
- **Qabul:** widget testlari; Z hisobot raqamlari savdolar bilan mos.
- **Bog'liq:** T-034

### [ ] T-042 Kassa ekrani — savat
- **Bajarish:** `pos-screen.md` bo'yicha: skanerlash → savatga qo'shish (bor bo'lsa miqdor +1), qidiruv (nomi, shtrix-kod, PLU), tez tugmalar paneli (non, tuxum kabi shtrix-kodsiz tovarlar), miqdor o'zgartirish, qatorni o'chirish, chegirma (huquq bo'yicha), ochiq savatni avtomatik saqlash, "kechiktirilgan chek" (2–3 ta parallel savat).
- **Qabul:** widget va golden testlar; 3000 tovarda qidiruv < 50 ms; ilova o'ldirilib qayta ochilsa savat tiklanadi.
- **Bog'liq:** T-040, T-041, T-030

### [ ] T-043 To'lov oynasi
- **Bajarish:** naqd (tez summalar: aniq, 50 000, 100 000, 200 000; qaytim katta), karta (terminalda to'landi deb belgilash), nasiya (mijoz tanlash, limit tekshiruvi), aralash to'lov. Tasdiqlash = bitta tranzaksiya (Sale + items + payments + stock + debt + outbox).
- **Qabul:** unit testlar (qaytim, aralash, limit); tranzaksiya atomarligi testi; to'lov 3 harakatda.
- **Bog'liq:** T-042, T-016 (klient tomoni T-060 bilan birga)

### [ ] T-044 Chek chop etish
- **Bajarish:** `printing.md` bo'yicha: ESC/POS 58/80 mm; Windows — o'rnatilgan printer yoki USB/tarmoq; Android — Bluetooth/USB/tarmoq. Chek shabloni, test chek, pul qutisini ochish, printer holati. Printer yo'q bo'lsa savdo to'xtamaydi.
- **Qabul:** chek matnini generatsiya qiluvchi funksiya uchun snapshot testlar; printersiz savdo ishlaydi.
- **Bog'liq:** T-043

### [ ] T-045 Qaytarish
- **Bajarish:** chek raqami yoki skanerlash orqali savdoni topish, to'liq/qisman qaytarish, sabab, naqd qaytarish yoki qarzdan ayirish. Huquq: menejer yoki ega PIN tasdiqlashi.
- **Qabul:** qaytarilgan miqdor sotilgandan oshmaydi; qoldiq va qarz to'g'ri.
- **Bog'liq:** T-043

### [ ] T-046 Kassaga pul kiritish/chiqarish
- **Bajarish:** sabab bilan; smena hisobotida ko'rinadi.
- **Qabul:** Z hisobotda naqd balansi to'g'ri.
- **Bog'liq:** T-041

---

## 4-bosqich. Tovarlar va ombor
Spec'lar: `products.md`, `stock-receipt.md`, `barcode.md`.

### [ ] T-050 Tovarlar ro'yxati va kartasi
- **Bajarish:** ro'yxat (qidiruv, kategoriya filtri, qoldiq, kam qolganlar belgisi), tovar qo'shish/tahrirlash: nom, kategoriya, birlik, sotish narxi, tannarx, shtrix-kodlar (skaner bilan qo'shish, bir nechta), vaznli tovar, PLU, min qoldiq, IKPU (ixtiyoriy). Narx tarixi.
- **Qabul:** skaner bilan yangi tovar kartasini ochish → shtrix-kod maydoni avtomatik to'ladi; takroriy shtrix-kod ogohlantiriladi.
- **Bog'liq:** T-040, T-033

### [ ] T-051 Excel/CSV import
- **Bajarish:** shablon yuklab olish, fayl tanlash, ustunlarni moslash, oldindan ko'rish, xatolar ro'yxati, import (yangi + yangilash shtrix-kod bo'yicha). Server tomonda katta fayllar uchun.
- **Qabul:** 5000 qatorli fayl import qilinadi; xato qatorlar aniq ko'rsatiladi.
- **Bog'liq:** T-050, T-014

### [ ] T-052 Kirim (tovar qabul qilish) skaner bilan
- **Bajarish:** `stock-receipt.md` bo'yicha: yetkazib beruvchi (ixtiyoriy), skanerlash → qatorga qo'shiladi yoki miqdor +1, miqdor/tannarx/sotish narxini tahrirlash, noma'lum shtrix-kod → tez tovar yaratish oynasi (shtrix-kod to'ldirilgan), qoralama saqlanadi, tasdiqlash → qoldiq oshadi (oflayn ham).
- **Qabul:** widget testlari; 100 ta skanerlash ketma-ket to'g'ri qo'shiladi; noma'lum kod oqimi testi.
- **Bog'liq:** T-050, T-035

### [ ] T-053 Inventarizatsiya skaner bilan
- **Bajarish:** to'liq yoki kategoriya bo'yicha; skanerlash bilan sanash; tizimdagi va haqiqiy farqi; tasdiqlash → tuzatish harakatlari.
- **Qabul:** farq hisoboti to'g'ri; tasdiqlangandan keyin qoldiq = sanalgan.
- **Bog'liq:** T-052

### [ ] T-054 Qoldiq harakatlari tarixi va kam qolganlar
- **Bajarish:** tovar bo'yicha harakatlar tarixi; kam qolganlar ro'yxati; "buyurtma ro'yxati" eksporti.
- **Qabul:** widget testlari.
- **Bog'liq:** T-052

---

## 5-bosqich. Mijozlar va nasiya
Spec: `debts.md`.

### [ ] T-060 Mijozlar va nasiya daftari
- **Bajarish:** mijozlar ro'yxati (qarzi borlar tepada), mijoz kartasi (qarz tarixi, xaridlar), qarzni qisman/to'liq to'lash, qarz limiti, kassada mijozni tez tanlash (ism/telefon qidiruv).
- **Qabul:** balans har doim DebtEntry yig'indisiga teng; oflaynda ishlaydi.
- **Bog'liq:** T-043

---

## 6-bosqich. Do'kon egasi hisobotlari (ilovada)
Spec: `reports.md`.

### [ ] T-070 Bosh sahifa va hisobotlar
- **Bajarish:** bugungi savdo, foyda, cheklar soni, o'rtacha chek; davr tanlash; top tovarlar; kassir bo'yicha; to'lov turlari; qarzlar; kam qolgan tovarlar. Oflaynda lokal ma'lumotdan, onlaynda serverdan.
- **Qabul:** raqamlar backend hisobotlari bilan mos (test ma'lumotlarida).
- **Bog'liq:** T-019, T-035

---

## 7-bosqich. Admin dashboard (Next.js) va obuna nazorati
Spec'lar: `admin-dashboard.md`, `subscription-billing.md`.

### [ ] T-080 Admin: kirish va layout
- **Bajarish:** login (platform_admin), JWT httpOnly cookie (Next.js route handler orqali), himoyalangan sahifalar, sidebar, yorug'/qorong'i.
- **Qabul:** Playwright: noto'g'ri parol xatosi, to'g'ri kirish, chiqish.
- **Bog'liq:** T-005, T-020

### [ ] T-081 Admin: bosh sahifa (KPI)
- **Bajarish:** faol mijozlar, sinovdagilar, MRR, shu oy to'lovlar, 7 kunda muddati tugaydiganlar, oxirgi sinxronlashi 3 kundan eski qurilmalar.
- **Qabul:** Playwright + API mock testlari.
- **Bog'liq:** T-080

### [ ] T-082 Admin: mijozlar (tenantlar)
- **Bajarish:** ro'yxat (qidiruv, holat filtri), yangi mijoz yaratish ustasi (do'kon, ega telefoni, vaqtinchalik parol, tarif, sinov muddati), mijoz sahifasi (obuna, to'lovlar, qurilmalar, foydalanuvchilar, oxirgi faollik), bloklash/blokdan chiqarish.
- **Qabul:** Playwright: yangi mijoz yaratish → ro'yxatda ko'rinadi → ega kassa ilovasiga kira oladi (API darajasida tekshiruv).
- **Bog'liq:** T-080

### [ ] T-083 Admin: tariflar, obunalar, to'lovlar
- **Bajarish:** tariflar CRUD, obunani uzaytirish (to'lovni qo'lda kiritish → muddat avtomatik uzayadi), to'lovlar ro'yxati va eksport (CSV).
- **Qabul:** to'lov kiritilganda muddat to'g'ri hisoblanadi (testlar).
- **Bog'liq:** T-082

### [ ] T-084 Admin: qurilmalar va audit jurnali
- **Bajarish:** barcha qurilmalar (versiya, oxirgi sinxron, bloklash), audit jurnali (filtr bilan).
- **Qabul:** Playwright testlari.
- **Bog'liq:** T-082

### [ ] T-085 Obuna nazorati ilovada
- **Bajarish:** muddat tugashiga 3 kun qolganda ogohlantirish banneri; grace — banner; readonly — savdo tugmalari o'chadi, aniq xabar va aloqa raqami; oflayn muddat (7 kun) qoidasi.
- **Qabul:** har holat uchun widget testlari.
- **Bog'liq:** T-035, T-013

---

## 8-bosqich. Sifat, chidamlilik, chiqarish

### [ ] T-090 Chidamlilik testlari
- **Bajarish:** integration testlar: 500 savdo oflayn → sinxron; push o'rtasida uzilish; savdo tranzaksiyasi o'rtasida jarayonni o'ldirish; 2 qurilma bir tovar; 10 000 tovar bilan qidiruv va ishga tushish vaqti.
- **Qabul:** hammasi yashil; natijalar `docs/PROGRESS.md` da.
- **Bog'liq:** T-043, T-035

### [ ] T-091 UI/UX sayqal
- **Bajarish:** `prompts/03-ui-review.md` bo'yicha barcha ekranlarni ko'rib chiqish; bo'sh holatlar, yuklanish, xato holatlari; klaviatura tezkor tugmalari; kontrast; matnlarni soddalashtirish.
- **Qabul:** tekshiruv ro'yxati `docs/ui-review.md` da to'liq bajarilgan.
- **Bog'liq:** 3–7 bosqichlar

### [ ] T-092 Production deploy
- **Bajarish:** `docker-compose.prod.yml` (gunicorn, nginx, postgres, redis), HTTPS (Caddy yoki nginx + certbot), kunlik baza zaxirasi (backup) va tiklash yo'riqnomasi, Sentry, `docs/DEPLOY.md`.
- **Qabul:** toza serverda yo'riqnoma bo'yicha 30 daqiqada ishga tushadi; backup'dan tiklash sinovdan o'tgan.
- **Bog'liq:** T-020

### [ ] T-093 Ilovani chiqarish
- **Bajarish:** Windows o'rnatuvchi (MSIX yoki Inno Setup), Android APK/AAB, versiyalash, ilova ichida yangi versiya haqida xabar, `docs/RELEASE.md`.
- **Qabul:** toza Windows kompyuterga o'rnatiladi va ishga tushadi.
- **Bog'liq:** T-090

### [ ] T-094 Foydalanuvchi qo'llanmasi
- **Bajarish:** `docs/user-guide/` — kassir uchun 1 sahifa, ega uchun 3–5 sahifa, skrinshotlar bilan (o'zbekcha).
- **Bog'liq:** T-091

---

## Keyinroq (hozir QILINMAYDI)
- Fiskal chek (virtual kassa / Multikassa / Arca), IKPU majburiy tekshiruvi
- Onlayn to'lov va QR (Click, Payme, Uzum, UzQR)
- Markirovka (Asl Belgisi, Data Matrix)
- SMS/Telegram qarz eslatmasi, ega uchun Telegram-bot
- Filiallar, sodiqlik/keshbek, distribyutorga buyurtma
- Obuna to'lovini onlayn qabul qilish
- Tarozi bilan to'g'ridan-to'g'ri ulanish, macOS
