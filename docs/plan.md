# O'z POS mahsulotimiz: fikr, yondashuv va yo'l xaritasi

*2026-yil 13-oktabr. Asos: [raqobatchilar tahlili](research.md).*

---

## 1. Fikrim (qisqa va ochiq)

**G'oya to'g'ri, vaqt ham mos.** 150–180 ming chakana do'konning katta qismi hali daftar yoki Excel'da; BILLZ qimmat va kiyim do'konlariga yo'naltirilgan, arzon segmentdagi PosPoint/Idokon esa hali zaif (brend yo'q, Idokon faqat Windows). "Oddiy, arzon, Android'da ishlaydigan, o'zbekcha kassa" uchun bo'sh joy bor.

**AI agent kodning 80–90% ini yoza oladi, lekin loyihani "to'liq o'zi" olib bora olmaydi.** Quyidagilar sizning (yoki odamning) zimmangizda qoladi:

| AI qila olmaydi | Nima uchun | Sizning ishingiz |
|---|---|---|
| Fiskal kassa reyestriga kirish, OFD bilan shartnoma | Yuridik shaxs, hujjatlar, davlat bilan muloqot | Avval tayyor fiskal modulga ulaning (Multikassa / Arca), o'z sertifikatlash keyinroq |
| Click / Payme / Uzum / UzQR merchant shartnomalari | API kalitlari faqat shartnomadan keyin beriladi | Kompaniya ochish, shartnoma imzolash |
| Haqiqiy uskunada sinash | Chek printeri, skaner, Sunmi terminal, tarozi — fizik qurilmalar | Har bir qurilmani qo'lda sinash, AI'ga natijani aytish |
| Kassirlar bilan suhbat va sinov | Do'konga borib kuzatish kerak | 10–15 do'kon egasi bilan gaplashish, pilot |
| Mahsulot qarorlari | "Nima qilamiz, nima qilmaymiz" — biznes tanlovi | Har bir bosqich oxirida qabul qilish |
| Pul va ma'lumot uchun javobgarlik | Xato chek = jarima, yo'qolgan savdo = ishonch yo'qolishi | Har bir PR'ni ko'rib chiqish, ayniqsa pul va fiskal qismda |

**Asosiy xavflar:**
1. **Fiskalizatsiya** — eng sekin va eng muhim qism. Fiskal cheksiz kassa qonuniy ishlata olmaydi. Shuning uchun birinchi kundan tayyor fiskal provayderga ulanish rejasi bo'lishi kerak.
2. **Oflayn ishlash** — viloyatda internet uziladi; savdo to'xtasa, do'kon tizimdan voz kechadi. Arxitektura oflayn-birinchi bo'lishi shart, keyin qo'shib bo'lmaydi.
3. **Hamma narsani birdaniga qilish** — eng ko'p uchraydigan xato. MVP faqat "sotish, chek, qoldiq, nasiya" bo'lsin.
4. **Raqobat** — BILLZ (TBC kapitali bilan) arzon segmentga tushishi, to'lov kompaniyalari bepul kassa qo'shishi mumkin. Javob: bitta segmentda eng sodda va eng tez bo'lish.

---

## 2. Yondashuv: bitta segment, bitta qurilma, bitta vazifa

- **Segment:** mahalla oziq-ovqat minimarketlari (1–2 kassa, 500–3000 xil tovar, ko'p nasiya).
- **Qurilma:** Windows kompyuter/monoblok (Flutter desktop) va Android/iOS telefon yoki planshet (Flutter mobil).
- **Va'da:** "Kassir 10 daqiqada o'rganadi, savdo 3 bosishda, internet yoki elektr uzilsa ham ma'lumot yo'qolmaydi."
- **Narx gipotezasi:** 99 000–149 000 so'm/oy abonent to'lovi.

---

## 3. MVP doirasi

*Yangilandi (13-oktabr, zelly talablari): onlayn to'lov, QR va fiskal chek hozir kirmaydi, kelajakda qo'shiladi. Mahsulot abonent (obuna) asosida sotiladi, shuning uchun alohida admin dashboard kerak.*

**A. Kassa ilovasi (Flutter: Windows desktop, Android, iOS). Filiallar yo'q: bitta do'kon, bir nechta kassa. Birinchi segment: oziq-ovqat.**
1. **Kassa ekrani:** shtrix-kod skaneri bilan sotish (USB/Bluetooth skaner va telefon kamerasi; kirim ham skaner bilan), qidiruv, savat, miqdor va vazn (kg), chegirma, naqd va karta (terminal orqali, qo'lda belgilanadi), qaytim, oddiy chek chop etish (fiskal emas).
2. **Tovarlar:** qo'shish (skanerlab), kategoriya, narx, tannarx, o'lchov birligi, Excel'dan import. IKPU maydoni hozirdan bo'ladi (keyingi fiskal uchun).
3. **Qoldiq:** kirim, savdoda avtomatik kamayish, minimal qoldiq ogohlantirishi, inventarizatsiya.
4. **Nasiya daftari:** qarzga sotish, qisman to'lash, mijoz qarz tarixi.
5. **Smena:** ochish/yopish, kassadagi naqd, kunlik hisobot.
6. **Xodimlar va huquqlar:** ega, menejer, kassir (PIN kod bilan tez kirish).
7. **Hisobotlar (do'kon egasi uchun):** savdo, foyda, top tovarlar, qarzlar.
8. **Oflayn rejim** va keyin sinxronlash (pastda 4.1).
9. **Til:** o'zbek lotin (asosiy), o'zbek kirill, rus. Yorug' va qorong'i mavzu.

**B. Admin dashboard (siz uchun, SaaS boshqaruvi):**
1. Mijozlar (do'konlar) ro'yxati: nomi, egasi, telefon, manzil, filiallar, qurilmalar.
2. Tariflar: narx, kassa/qurilma soni, filial soni, funksiyalar cheklovi.
3. Obuna: boshlanish va tugash sanasi, sinov muddati (masalan 7–14 kun), to'lovni qo'lda belgilash (MVP'da), to'lovlar tarixi.
4. Muddati o'tganda: ogohlantirish (3 kun oldin), keyin imtiyozli muddat, keyin faqat o'qish rejimi (savdo bloklanadi, ma'lumot o'chmaydi).
5. Qurilmalar: har bir kassa qurilmasini ro'yxatdan o'tkazish, bloklash, oxirgi sinxronlash vaqti.
6. Umumiy ko'rsatkichlar: faol mijozlar, oylik daromad (MRR), muddati tugayotganlar.
7. Admin harakatlari jurnali (kim nimani o'zgartirdi).

**Kirmaydi (keyinroq):** fiskal chek va OFD, onlayn to'lov (Click/Payme/Uzum), QR to'lov, markirovka, SMS eslatma, sodiqlik, distribyutorga buyurtma, obuna to'lovini onlayn qabul qilish.

---

## 4. Texnologiya (stack)

*Yangilandi: zelly tanlovi bo'yicha Python Django + Flutter.*

| Qism | Tanlov | Izoh |
|---|---|---|
| Backend | Python 3.12, Django 5, Django REST Framework | API, auth, sinxronlash, obuna |
| Baza (server) | PostgreSQL | Har bir do'kon ma'lumoti `tenant_id` bilan ajratiladi |
| Auth | JWT (SimpleJWT) + qurilma tokeni | Kassir PIN kodi qurilma ichida tekshiriladi, oflayn ham ishlaydi |
| Fon vazifalar | Celery + Redis | Obuna muddati tekshiruvi, hisobotlar, import |
| API hujjat | drf-spectacular (OpenAPI) | Flutter uchun Dart klient avtomatik generatsiya qilinadi |
| Kassa ilovasi | Flutter (Windows desktop, Android, iOS) | Bitta kod bazasi |
| Lokal baza | SQLite + Drift | Oflayn-birinchi, tranzaksiyalar, tez qidiruv |
| State | Riverpod | Sinovga qulay, keng tarqalgan |
| Dizayn | Material 3 asosida o'z dizayn tizimi (tokenlar, komponentlar) | Desktop va mobil uchun bitta uslub |
| Admin dashboard | Next.js (App Router, TypeScript, Tailwind, shadcn/ui) | zelly tanlovi |
| Testlar | pytest (backend), flutter_test + golden testlar (UI), integration_test | Agent o'z ishini o'zi tekshiradi |
| CI/CD | GitHub Actions; Docker Compose (dev va server) | Har PR'da test + lint + build |
| Xatolar | Sentry (Django va Flutter) | |

**Repo tuzilishi (monorepo):**
```
pos/
  backend/            Django loyiha (apps: accounts, tenants, billing, catalog, inventory, sales, debts, sync, reports)
  apps/pos/           Flutter kassa ilovasi (desktop + mobil)
  apps/admin/         Next.js admin dashboard
  packages/ui/        Umumiy dizayn tizimi (Flutter package)
  packages/api_client/ OpenAPI'dan generatsiya qilingan Dart klient
  docs/specs/  docs/decisions/
  CLAUDE.md
```

**Pul qoidasi:** barcha summalar butun son (tiyin), Python'da `int`/`Decimal`, Dart'da `int`; hech qachon `float`.

### 4.1. Oflayn va onlayn ishlash (internet va elektr uzilishi)

1. **Kassa hamma ishni lokal SQLite'da qiladi.** Server faqat sinxronlash uchun. Internet yo'qligi savdoga hech qachon to'sqinlik qilmaydi.
2. **Elektr o'chishiga chidamlilik:** har savdo bitta SQLite tranzaksiyasida yoziladi (WAL rejimi); chek "yopildi" deb ko'rsatilishidan oldin diskka yozilgan bo'ladi. Ilova qayta ochilganda ochiq savat tiklanadi.
3. **Savdolar o'zgarmas voqealar:** har savdo, qaytarish, kirim, qarz to'lovi UUID bilan yaratiladi va "chiquvchi navbat"ga (outbox) tushadi. Internet paydo bo'lganda navbat serverga yuboriladi; server UUID bo'yicha takrorlarni rad etadi (idempotent).
4. **Katalog (tovar, narx) serverdan pastga sinxron:** `updated_at` / versiya bo'yicha faqat o'zgarganlar olinadi.
5. **Qoldiq to'qnashuvi:** bir nechta kassa oflayn sotganda qoldiq manfiy bo'lishi mumkin, bu bloklanmaydi, hisobotda belgilanadi. Qoldiq = harakatlar yig'indisi (kirim − sotuv ± tuzatish), shuning uchun yo'qolmaydi.
6. **Obuna oflaynda:** qurilma oxirgi muvaffaqiyatli tekshiruvdan keyin ma'lum muddat (masalan 7 kun) oflayn ishlaydi; muddati o'tgan obuna tekshiruvi internet qaytganda bajariladi.
7. **Holat ekranda:** "Internet yo'q, 12 ta savdo navbatda" kabi aniq va tinch xabar.

---

## 5. Yo'l xaritasi

Har bosqich "tayyor" deb hisoblanishi uchun **chiqish mezoni** bor.

### 0-bosqich: Tushunish va dizayn
- 10–15 do'kon egasi va kassir bilan suhbat; 3–5 do'konda savdoni kuzatish.
- Asosiy ekranlar bosiladigan prototipi (kassa, to'lov, tovar qo'shish, nasiya, admin dashboard) va kassirlarda sinash.
- **Chiqish mezoni:** kassir prototipda yordamsiz savdo qila oladi; 3 ta do'kon "tayyor bo'lsa ishlataman" deydi.

### 1-bosqich: Poydevor
- Monorepo, CLAUDE.md, Docker Compose, CI.
- Django: tenant modeli, foydalanuvchilar, rollar, JWT, OpenAPI.
- Flutter: dizayn tizimi paketi (ranglar, shriftlar, tugmalar, kassa klaviaturasi, yorug'/qorong'i mavzu), Drift baza, navigatsiya, 3 til.
- **Chiqish mezoni:** ilova Windows va Android'da ochiladi, serverga kiradi; CI yashil.

### 2-bosqich: Oflayn kassa
- Tovarlar, skaner, savat, naqd/karta, chek printeri, qoldiq, smena, nasiya, PIN bilan kirish — hammasi internetsiz.
- **Chiqish mezoni:** haqiqiy qurilmada 100 ta ketma-ket savdo xatosiz; savdo o'rtasida elektrni o'chirib yoqish ma'lumot yo'qotmaydi; o'rtacha savdo 15 soniyadan kam.

### 3-bosqich: Sinxronlash va do'kon egasi hisobotlari
- Outbox sinxronlash, katalog sinxronlash, bir nechta kassa, ega uchun hisobotlar (ilovada).
- **Chiqish mezoni:** 2 kun oflayn ishlagan 2 ta kassa ulanganda barcha savdolar dublikatsiz serverga tushadi, qoldiq to'g'ri chiqadi.

### 4-bosqich: Admin dashboard va obuna
- Mijozlar, tariflar, obuna, qurilmalar, bloklash, MRR, admin jurnali.
- **Chiqish mezoni:** yangi do'konni 5 daqiqada ro'yxatdan o'tkazib, qurilmasini ulash mumkin; muddati o'tgan obuna avtomatik cheklanadi.

### 5-bosqich: Pilot (3–5 do'kon)
- **Chiqish mezoni:** do'konlar 1 oy davomida daftarga qaytmaydi; kamida 2 tasi pul to'lashga tayyor.

### 6-bosqich: Kengayish
- Fiskal chek (Multikassa/Arca yoki virtual kassa reyestri), onlayn to'lov va QR (Click/Payme/Uzum/UzQR), markirovka, SMS/Telegram qarz eslatmasi, obuna to'lovini onlayn qabul qilish, ko'p filial, tarozi, macOS.

> Muhim: fiskal chek qo'shilmaguncha do'konlar tizimni fiskal kassa bilan birga (parallel) ishlatishi kerak bo'ladi. Pilot uchun bu normal, lekin keng sotuvdan oldin fiskal bo'lishi kerak.

---

## 6. AI agent bilan qanday ishlash kerak

**Asosiy qoida:** agent sizning muhandislik jamoangiz, siz esa mahsulot egasi va sifat nazoratchisisiz. Agent "nima qilish"ni emas, "qanday qilish"ni hal qiladi.

1. **Repo ildizida `CLAUDE.md`** — loyiha konstitutsiyasi: maqsad, stack, papkalar tuzilishi, kod uslubi, pul qoidasi, tillar, "hech qachon qilma" ro'yxati (testni o'chirma, float pul ishlatma, kassirga inglizcha xabar ko'rsatma va h.k.).
2. **Har bir funksiya uchun qisqa spec** (`docs/specs/nasiya.md`): foydalanuvchi hikoyasi, ekranlar, qabul mezonlari ("Kassir mijozni tanlab, 'Qarzga' tugmasini bossa..."), chekka holatlar. Spec'ni agent bilan birga yozing, keyin kod.
3. **Kichik vazifalar.** Bitta vazifa = bitta PR = bir kunda ko'rib chiqsa bo'ladigan hajm. "Butun kassani yoz" emas, "savatga tovar qo'shish va miqdorni o'zgartirish".
4. **Testlar majburiy.** Pul hisobi, qoldiq, nasiya, sinxronlash uchun unit testlar; asosiy savdo oqimi uchun e2e test. Agent testni o'zi yozadi va yashil bo'lmaguncha PR'ni tayyor demaydi.
5. **Siz ko'rib chiqasiz.** Har PR'da: skrinshot yoki video (agent Flutter golden testlari orqali olishi mumkin), nima o'zgardi, qanday sinaldi. Pul va fiskal qismida diqqat bilan o'qing.
6. **Haftalik sikl:** dushanba — reja va spec'lar; hafta davomida — agent PR'lar ochadi, siz ko'rib chiqasiz; juma — haqiqiy qurilmada sinash va do'kondan fikr.
7. **Qarorlar jurnali** (`docs/decisions/`): "Nima uchun Expo tanladik", "Nima uchun voqealar jurnali" — keyingi sessiyalardagi agent qayta bahslashmasligi uchun.
8. **Staging va feature flag'lar:** yangi funksiya avval sizning test do'koningizda, keyin pilotlarda.

---

## 7. UI/UX tamoyillari (kassir uchun)

Kassir — shoshib turgan, navbat oldida turgan, ko'pincha texnikaga qiziqmaydigan odam. Dizaynning har bir qarori shunga xizmat qilsin.

1. **Asosiy ekran = kassa.** Ilova ochilganda darhol savdo ekrani. Boshqa hamma narsa (tovarlar, hisobot) ikkinchi darajada.
2. **3 bosishda savdo:** skanerlash → "To'lash" → "Naqd/Karta/QR". Qaytim katta raqam bilan ko'rinadi.
3. **Katta tugmalar:** kamida 56×56 px, barmoq bilan xato bosilmasin; asosiy harakat tugmasi ekranning pastki o'ng qismida, doim bir joyda.
4. **Skaner birinchi:** skaner har doim tayyor, fokusni qidirish shart emas; ovozli va rangli tasdiq ("bip" + yashil chiziq), topilmasa — aniq xabar va "Yangi tovar qo'shish" tugmasi.
5. **O'zbekcha, oddiy so'zlar:** "Chek yopildi", "Qaytim: 12 000 so'm". Texnik so'zlar yo'q ("sinxronizatsiya xatosi" emas, "Internet yo'q, savdo saqlandi").
6. **Xatoni tuzatish oson:** har harakatni bekor qilish mumkin; o'chirishdan oldin bitta tasdiq, ortiqcha modal oynalar yo'q.
7. **Holat doim ko'rinadi:** internet, printer, smena holati yuqori qatorda kichik belgilar bilan.
8. **Raqamlar o'qilishi oson:** 125 000 (bo'shliq bilan), so'm doim yozilgan, jami summa ekrandagi eng katta matn.
9. **Yuqori kontrast,** quyosh tushadigan do'konda ham o'qiladi; rang faqat ma'no uchun (yashil = muvaffaqiyat, qizil = xato), faqat rangga tayanmaslik.
10. **Moslashuvchan maket:** telefon (bir ustun, pastda to'lash tugmasi), planshet va desktop (chapda tovarlar, o'ngda savat). Desktop'da klaviatura tezkor tugmalari (F1 qidiruv, F12 to'lash, Esc bekor). Har ekran uchala o'lchamda sinaladi.
13. **Zamonaviy ko'rinish:** toza tipografiya, yumshoq soyalar, bir xil burchak radiuslari, yengil animatsiyalar (200 ms dan oshmaydi), yorug' va qorong'i mavzu. Zamonaviylik tezlik hisobiga bo'lmasligi kerak.
11. **Tezlik:** har bosishga 100 ms ichida javob; 3000 tovarlik qidiruv bir zumda.
12. **Sinov:** har yangi ekranni 3 ta haqiqiy kassirga ko'rsating, hech narsa tushuntirmasdan; ular qayerda to'xtasa, o'sha yer qayta ishlanadi. "Bitta savdo necha soniya" ko'rsatkichini doim o'lchang.

---

## 8. Keyingi aniq qadamlar

1. Ochiq savollarga javob (thread'da).
2. GitHub'da bo'sh repo yaratib, shu loyihaga ulash.
3. Agent poydevorni quradi: monorepo, CLAUDE.md, Django skeleti, Flutter skeleti, dizayn tizimi, CI.
4. Kassa ekranining bosiladigan prototipini kassirlarda sinash.
5. Parallel: do'konlar bilan suhbat; fiskal provayder va to'lov kompaniyalari bilan muloqot (keyingi bosqich uchun).
