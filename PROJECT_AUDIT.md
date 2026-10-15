# PROJECT_AUDIT — butun tizim auditi (2026-10-15)

Audit 5 yo'nalishda olib borildi (har biri alohida agent tomonidan, kod o'qib, backend xatolari esa vaqtinchalik pytest bilan takrorlab).
Batafsil hisobotlar — har bir topilma uchun **joy (fayl:qator), asl sabab, ta'sir, tuzatish, test**:

| Yo'nalish | Batafsil |
|---|---|
| UI/UX, dizayn tizimi, yashil chaqnash | [docs/audit/audit_ui.md](docs/audit/audit_ui.md) |
| Mahsulotlar: nom, qidiruv, sinxron, rasm | [docs/audit/audit_products.md](docs/audit/audit_products.md) |
| Kirim, qoldiq, inventarizatsiya | [docs/audit/audit_receipts.md](docs/audit/audit_receipts.md) |
| Mijozlar, qarz, balans | [docs/audit/audit_customers.md](docs/audit/audit_customers.md) |
| Chek, printer | [docs/audit/audit_printing.md](docs/audit/audit_printing.md) |

Ish jarayoni va holat: [AGENT_WORKLOG.md](AGENT_WORKLOG.md).

## Mahsulot doirasi (audit natijasi)
- **Kassa ilovasi (Flutter, `apps/pos`)** — do'kon ishlatadigan yagona ilova: kassa, tovarlar, kirim, inventarizatsiya, mijozlar/nasiya,
  smena, hisobotlar, sozlamalar, printer. Oflayn-birinchi: lokal SQLite + outbox → server.
- **Admin panel (Next.js, `apps/admin`)** — faqat platforma admini uchun (mijoz-do'konlar, tariflar, to'lovlar, qurilmalar, audit).
  Unda mahsulot, kirim yoki mijoz sahifalari **yo'q** — bular kassa ilovasida.
- **Mavjud emas va yaratilmaydi** (doiradan tashqari yoki ROADMAP'da "Keyinroq"): yetkazib beruvchi qarzi/to'lovlari, fiskal chek,
  onlayn to'lov, filiallar. Yetkazib beruvchilar ro'yxati bor (kirimda tanlash uchun), lekin ularning balansi yo'q.

## Topilmalar (ustuvorlik bo'yicha) va holat

Holat: ✅ tuzatildi · 🔧 ishlanmoqda · ⏳ rejada · ❓ biznes savoli (`docs/QUESTIONS.md`)

### P0 — ma'lumot yo'qotish yoki ishni to'xtatish

| # | Muammo | Asl sabab | Ta'sir | Holat |
|---|---|---|---|---|
| UI-1 | Tovarni bosganda butun panel/sahifa yashil chaqnaydi | Skaner chaqnashi (`PosScanFeedback`) oddiy bosishda ham chaqiriladi, butun panelni o'raydi va fonni 10% yashil bo'yaydi, 350 ms | Ko'zni charchatadi, "xato bo'ldimi?" degan tuyg'u | ✅ chaqnash faqat skanerda, faqat 2 px chegara, 200 ms |
| UI-2 | Kassa tez tugmasida `RenderFlex overflowed by 4 px` (ilova logida) | Plitka balandligi 88 px, 2 qatorli nom + narx 92 px talab qiladi | Narx kesiladi, sariq-qora chiziq (debug) | ✅ 96 px |
| CU-B1 | Telefon formatsiz yozilsa ("90 123 45 67") mijoz serverga yetmaydi, uning **nasiya savdolari ham rad etiladi** | Server faqat `+998XXXXXXXXX` qabul qiladi, kassa yozilganicha yuboradi | Qarz yozuvlari serverda yo'q — hisobot va boshqa kassalarda noto'g'ri qarz | ✅ server va kassa bir xil normallashtiradi, kassada xato xabari |
| CU-B2 | Server hali olmagan mijozga nasiya savdosi — rad etiladi | `record_sale` "Unknown customer" → `invalid` (kutish o'rniga) | Savdo serverda yo'qoladi | ✅ `MissingDependency` → pending |
| PR-P0-1 | Server rad etgan tovar (masalan, ikki kassada bir xil shtrix-kod) — shu tovar bor **barcha savdolar ham rad etiladi** | Savdo/kirim noma'lum tovarni `invalid` qiladi; tovar hodisasi to'liq rad etiladi | Savdolar, to'lovlar, qarzlar serverga yetmaydi | ✅ T-101 |
| PR-P0-2 | Matnda NUL (`\u0000`) belgisi — kassa sinxroni **butunlay to'xtaydi** | `SyncEvent.save` try'dan tashqarida; Postgres jsonb NUL saqlay olmaydi → 500 | Kassa "oflayn", hech narsa yuborilmaydi | ✅ T-101 |
| RC-B1 | Serverda o'chirilgan tovar/yetkazib beruvchiga oflayn kirim — rad etiladi | Sinxron handler o'chirilgan qatorlarni topmaydi | Kirim serverda yo'q, kassa qoldig'i esa uni hisoblaydi | ✅ T-101 |
| RC-B4 | Inventarizatsiya "kutilgan"ni server qo'llash paytida hisoblaydi | Kechikkan savdolar ikki marta ayiriladi yoki o'chib ketadi | Qoldiq noto'g'ri | ⏳ keyinroq (inventarizatsiya hodisasiga kassa vaqti/kutilgan qiymat kerak; qaror talab qiladi) |

### P1 — asosiy funksiya yo'q yoki noto'g'ri

| # | Muammo | Holat |
|---|---|---|
| RC-0 | Tasdiqlangan **kirimni tahrirlash va bekor qilish imkoni yo'q** (serverda bekor qilish endpoint'i bor, lekin kassa ishlatmaydi) | ✅ T-102 (teskari yozuv + yangi versiya, atomar; qaror 0010) |
| CU-0 | Mijoz yaratishda **boshlang'ich balans** yo'q | ⏳ T-103 |
| PRN-0 | Chek sozlamalari bo'limi yo'q: preview, logotip, STIR, ko'rsat/yashir; do'kon ma'lumotini faqat Django admin o'zgartiradi | ⏳ T-104 |
| PRN-B4 | Xprinter turidagi printerlarda kirillcha xitoycha belgilar bo'lib chiqishi mumkin (`FS .` yuborilmaydi) | ⏳ T-104 |
| PRN-B12 | Aralash to'lovda chekda naqd *berilgan* summa to'lov sifatida chiqadi (to'lovlar yig'indisi JAMI dan katta) | ⏳ T-104 |
| PRN-B13 | Birinchi chop etish xato bo'lsa, qayta urinish mijozga "NUSXA" belgili chek chiqaradi | ⏳ T-104 |
| PRN-B14 | Avto-chop o'chiq bo'lsa naqd savdoda pul qutisi ochilmaydi | ⏳ T-104 |
| IMG-0 | Mahsulot rasmi umuman yo'q | ⏳ T-105 |
| PR-P1-3 | Kassada nom ≤ 200 va ≤ 20 shtrix-kod cheklovi yo'q → server rad etadi (P0-1 ga olib keladi) | ✅ T-101 |
| PR-P1-4 | Oflayn eski tahrir serverdagi yangi narxni qaytarib yozadi (to'liq snapshot) | ⏳ T-106 (o\'zgargan maydonlar — kassa formati o\'zgaradi) |
| PR-P1-6, UI-P1-3 | Saqlashda kutilmagan xato — tugma "yuklanmoqda"da qotadi, xabar yo'q (tovar kartasi, mijoz kartasi, smena yopish) | ⏳ T-106 |
| UI-P1-2, UI-P1-4 | Ikki marta bosish: tovar kartasi ikki tovar, kirim ikki qoralama, yetkazib beruvchi ikki marta yaratadi | ⏳ T-106 |
| UI-P1-1 | Kirim/inventarizatsiya qoralamasi tasdiqsiz va qaytarishsiz o'chadi (tugma "Tasdiqlash" yonida) | kirim ✅ T-102 (`showPosConfirm`); inventarizatsiya ⏳ T-106 |
| UI-P1-5 | Telefonda holat qatori kesiladi ("Prin…"), smena va xato ko'rinmaydi | ⏳ T-106 |
| CU-B3 | Qayta yuborilgan qarz to'lovi smena yopilgach rad etiladi | ✅ T-101 |
| CU-B4 | Smena ochilmasdan qarz to'lovi qabul qilinadi — naqd hech bir Z-hisobotga tushmaydi | ⏳ T-103 |
| RC-B5/B6 | Javob yo'qolib qayta yuborish kutilayotganda pull qoldiqni ikki marta hisoblaydi va kirim narxini eskisi bilan almashtiradi (≤ 5 daqiqa) | ✅ T-101 |

### P2 — sifat, izchillik

- **UI:** holat qatorida doimiy yorqin yashil (internet/printer/smena) — normal holat neytral bo'lishi kerak; pul maydonlari "11000"
  (bo'shliqsiz); majburiy/ixtiyoriy belgisi yo'q; ro'yxatda xato bo'lsa cheksiz spinner; skeleton o'rniga spinner; telefonda 6 ta pastki tab;
  yuklanayotgan tugma klaviatura fokusini yo'qotadi. → T-106
- **Mahsulot:** qidiruvda `´` apostrof emas; nomlarda `\n`/`\t` server qabul qiladi; REST `plu_code=""` ikkinchi marta 409; dublikat nom
  ogohlantirishi yo'q; o'chirilgan tovar kartasi "yangi" bo'lib ochiladi. → T-101/T-106
- **Chek:** "·", « », “ ”, … qog'ozda `?`; Ў/ў CP866 da bor, lekin У ga aylantiriladi; bo'sh do'kon nomi bo'sh qator; gramm/qadoq
  birligi ko'rinmaydi; telefon formatlanmagan. → T-104
- **Kirim:** narxlar hodisa vaqti emas, kelish tartibida qo'llanadi (eski oflayn kirim yangi narxni bosadi); kirim vaqti server vaqti;
  boshqa kassadagi kirimlar ko'rinmaydi. → T-102
- **Mijoz:** manfiy balans "Qarz: −X" ko'rinadi (avans sifatida emas); yangi mijoz oynasida Enter + bosish ekranni ikki marta yopadi. → T-103

### Yaxshi ishlayotganlar (tekshirildi)
- Pul faqat butun tiyin; kirim/savdo/qarz yozuvlari o'zgarmas; serverda qoldiq — harakatlar jurnali (+ kesh, `rebuild_stock`).
- Uzbek apostroflari (ʻ ʼ ‘ ’), kirill harflari serverda o'zgarmay saqlanadi; qidiruv `yog'` → `Yogʻ`/`Ёғ` topadi.
- Ro'yxat va forma bir manbadan (lokal jadval) o'qiydi; nom/sarlavha chalkashligi yo'q.
- Chek qatorlari kenglikka to'g'ri o'raladi, katta summalar (12 345 678 so'm) sig'adi, vaznli miqdor, chegirma va qaytim to'g'ri.
- To'lov, kassa puli, qaytarish, qarz to'lovi oynalari ikki marta bosishdan himoyalangan.
- Ruxsatlar matritsasi spec'ga mos; REST tenant izolyatsiyasi testlangan.
- Mavzu (theme): splash/highlight ranglari neytral, past shaffoflikda — chaqnashga aloqasi yo'q.

## Biznes savollari (yangi, `docs/QUESTIONS.md` ga yoziladi)
- Kirimni qancha vaqt ichida tahrirlash mumkin? Inventarizatsiyadan keyin eski kirimni tahrirlash — bloklashmi yoki ogohlantirishmi?
- Mijoz avansi (do'kon mijozga qarzdor) — Q-003 ga bog'liq; kassir boshlang'ich qarz kirita oladimi?
- Chekda STIR yoki JShShIR, qaysi nom bilan? Rekvizitlarni kim o'zgartiradi (ega/menejer)?

## Jismoniy sinov cheklovlari
- Haqiqiy printer ulanmagan: chek formatlash unit/golden testlar va preview orqali tekshiriladi; jismoniy printerda sinov **qilinmagan**.
- Android qurilma yo'q (T-047, Q-007).
