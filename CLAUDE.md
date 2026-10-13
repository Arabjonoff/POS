# POS — loyiha konstitutsiyasi (AI agent uchun)

Mahalla oziq-ovqat do'konlari uchun (keyin boshqa chakana do'konlar) **obuna (abonent) asosidagi kassa va ombor tizimi**.
Ilova internet yoki elektr uzilsa ham to'xtamasligi va ma'lumot yo'qotmasligi kerak. UI/UX — mahsulotning eng muhim qismi.

Har sessiya boshida o'qi:
0. **`docs/STATE.md` — birinchi navbatda.** Unda ish tugallanmagan bo'lsa, `prompts/05-resume.md` bo'yicha davom et.
1. `docs/ROADMAP.md` — vazifalar ro'yxati va holati. Ishni doim shu yerdan ol.
2. `docs/specs/` — har funksiya uchun spec. Kod spec'ga mos bo'lishi shart.
3. `docs/decisions/` — qabul qilingan qarorlar. Ularni qayta bahslashma.
4. `docs/PROGRESS.md` — oldingi sessiyalar nima qilgani (oxiriga yoz).

## Stack (o'zgartirilmaydi)
| Qism | Texnologiya | Papka |
|---|---|---|
| Backend API | Python 3.12, Django 5.2, Django REST Framework, PostgreSQL 16, SimpleJWT, drf-spectacular, pytest | `backend/` |
| Kassa ilovasi | Flutter (stable), Dart 3, Riverpod, Drift (SQLite), go_router; **Windows desktop, Android, iOS** | `apps/pos/` |
| Dizayn tizimi | Flutter package, tokenlar + komponentlar, Widgetbook | `packages/ui/` |
| Admin dashboard | Next.js (App Router), TypeScript, Tailwind CSS, shadcn/ui, TanStack Query, Playwright | `apps/admin/` |
| API klientlar | OpenAPI sxemasidan generatsiya (Dart va TypeScript), qo'lda tahrirlanmaydi | `packages/api_client_dart/`, `apps/admin/src/api/` |
| Infra | Docker Compose (postgres, redis, backend, admin), GitHub Actions | `docker-compose.yml`, `.github/` |

Filiallar MVP'da yo'q: bitta do'kon, bir nechta kassa. Lekin `Store` modeli bor (kelajak uchun).
Fiskal chek, onlayn to'lov, QR to'lov, markirovka — **hozir qilinmaydi** (ROADMAP'da "Keyinroq").

## Buyruqlar (to'liq ro'yxat: `make help`)
- Hammasini ishga tushirish: `make up` (= `docker compose up -d`)
- Backend testlar: `make backend-test` (= `cd backend && uv run pytest`) ; lint: `make backend-lint` (= `uv run ruff check . && uv run ruff format --check .`)
- Flutter: `make pos-analyze && make pos-test` (= `cd apps/pos && flutter analyze && flutter test`)
- Dizayn tizimi: `make ui-test` (= `cd packages/ui && flutter test`, golden testlar)
- Admin: `make admin-lint admin-test admin-e2e` (= `cd apps/admin && npm run lint && npm run typecheck && npm test && npx playwright test`)
- API klientlarni yangilash: `make api-clients`
- Python bog'liqliklari `uv` bilan boshqariladi (`backend/pyproject.toml`, `uv.lock`); Dart — ildizdagi pub workspace (`flutter pub get` ildizda).

## Buzilmaydigan qoidalar
1. **Pul faqat butun son — tiyin.** Python `int`, Dart `int`, TypeScript `number` (butun) yoki `bigint`. `float`/`double` pul va miqdor uchun taqiqlangan. Miqdor — `qty_milli` (1 dona = 1000, 0,250 kg = 250).
2. **Kassa oflayn-birinchi.** Savdo, kirim, qarz — hech biri tarmoq so'roviga bog'liq emas. Avval lokal SQLite tranzaksiyasi, keyin outbox orqali server. Batafsil: `docs/specs/sync.md`.
3. **Savdo, qaytarish, kirim, qarz harakati o'zgarmas.** Tahrir yo'q — faqat teskari yozuv. ID — klientda yaratilgan UUIDv7.
4. **Har server so'rovi tenant bo'yicha cheklanadi.** Har yangi endpoint uchun "boshqa tenant ma'lumotini ko'ra olmaydi" testi majburiy.
5. **Shtrix-kod skaneri har doim ishlaydi.** Sotuv va kirim ekranlarida skaner kiritishi fokus qayerda bo'lishidan qat'i nazar to'g'ri joyga tushadi. `docs/specs/barcode.md`.
6. **Foydalanuvchiga ko'rinadigan matn faqat tarjima fayllarida** (uz-Latn asosiy, uz-Cyrl, ru). Kodda qattiq yozilgan matn yo'q. Xabarlar oddiy o'zbekcha, texnik so'zsiz.
7. **Ekranlar faqat `packages/ui` komponentlari va tokenlaridan quriladi.** Rang, o'lcham, shrift kodda qattiq yozilmaydi.
8. **Testni o'chirma, `skip` qilma, zaiflashtirma.** Yiqilsa — kodni tuzat.
9. **Sirlar repoga tushmaydi.** `.env` gitignore'da, faqat `.env.example`.
10. **Migratsiyalar orqaga mos.** Eski versiyadagi kassa yangi serverga sinxronlay olishi shart.

## UI/UX qoidalari (qisqa; to'liq: `docs/specs/design-system.md`)
- Ilova ochilganda (PIN'dan keyin) — darhol kassa ekrani.
- Savdo 3 harakatda: skanerlash → To'lash (F12) → to'lov turi.
- Bosiladigan element ≥ 48 dp, kassa asosiy tugmalari ≥ 56 dp.
- Jami summa — ekrandagi eng katta matn. Format: `125 000 so'm`.
- Windows: F1 qidiruv, F2 miqdor, F4 mijoz, F8 qaytarish, F12 to'lash, Esc bekor, Delete qatorni o'chirish.
- Telefon — bir ustun; planshet/desktop — chapda qidiruv va tez tugmalar, o'ngda savat.
- Yorug' va qorong'i mavzu. Animatsiya ≤ 200 ms. Har bosishga javob ≤ 100 ms.
- Holat qatori doim ko'rinadi: internet, printer, smena, sinxronlanmagan yozuvlar soni.

## Ish tartibi (har vazifa uchun)
0. `docs/STATE.md` ni tekshir: tugallanmagan ish bo'lsa — avval o'shani tugat.
1. `docs/ROADMAP.md` dan birinchi bajarilmagan va bog'liqliklari tayyor vazifani ol.
2. Tegishli spec'ni o'qi. Spec yo'q yoki noaniq bo'lsa — avval spec'ni yoz/to'ldir (`docs/specs/`), keyin kod.
3. Yangi branch: `feat/T-XXX-qisqa-nom`.
4. Kod + testlar. Barcha tekshiruvlar (lint, analyze, test) yashil bo'lmaguncha tugadi dema.
5. UI vazifalarida golden testlar va skrinshotlar (telefon 390×844, planshet 1024×768, desktop 1440×900) — `docs/screenshots/T-XXX/`.
6. Commit (Conventional Commits: `feat(pos): ...`), push, PR. PR tavsifi: nima, nima uchun, qanday sinaldi, skrinshotlar.
7. CI yashil bo'lsa — PR'ni `main`ga merge qil (squash).
8. `docs/ROADMAP.md` da vazifani `[x]` qil, `docs/PROGRESS.md` oxiriga 3–5 qator yoz (nima qilindi, nima qoldi, muammolar).
9. Qaror qabul qilinsa — `docs/decisions/NNNN-nom.md`.

## Uzilishlarga chidamli ishlash (elektr va internet tez-tez o'chadi)
Ish istalgan soniyada to'xtashi mumkin. Shuning uchun:
1. **Vazifa boshida** `docs/STATE.md` ga vazifa, branch va qadamlar ro'yxatini (5–10 ta kichik qadam) yoz, commit va push qil.
2. **Har qadamdan keyin** (eng ko'pi 15–20 daqiqa ish): STATE.md dagi qadamni `[x]` qil, "Oxirgi bajarilgan ish" va "Keyingi aniq harakat"ni yangila, `wip: T-XXX <qadam>` commit, `git push`. Push qilinmagan ish — yo'qolgan ish.
3. **"Keyingi aniq harakat"** shunday yozilsin-ki, xotirasiz yangi sessiya uni o'qib darhol davom eta olsin (fayl nomi, funksiya, buyruq).
4. Uzoq buyruqdan (build, katta test, migratsiya) **oldin** STATE.md da "Ishlab turgan: <buyruq>" deb yoz.
5. Sinab ko'rilgan va ishlamagan yechimlarni "Eslatmalar"ga yoz — keyingi sessiya qaytarmasin.
6. Vazifa tugaganda STATE.md ni bo'sh shablonga qaytar ("Joriy vazifa: —") va PROGRESS.md ga yozuv qo'sh.
7. PR merge qilishda `wip:` commitlar squash bilan birlashtiriladi, shuning uchun ular tarixni buzmaydi.

## To'xtash va so'rash kerak bo'lgan holatlar
Quyidagilarda ishni to'xtatma, lekin `docs/QUESTIONS.md` ga savol yoz va keyingi mustaqil vazifaga o't:
- Spec'lar bir-biriga zid; biznes qarori kerak (narx, tarif, huquqlar).
- To'lov, pul yoki ma'lumot o'chirish bilan bog'liq noaniqlik.
- Tashqi xizmat uchun kalit/shartnoma kerak.
- Bir vazifa 3 urinishdan keyin ham yashil bo'lmasa.
