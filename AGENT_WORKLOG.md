# AGENT_WORKLOG — professional darajaga olib chiqish (audit → tuzatish)

> Bu fayl ish jurnali va nazorat nuqtasi. Sessiya uzilsa — avval shu faylni, keyin `docs/STATE.md` ni o'qib, "Keyingi qadam"dan davom et.
> Audit natijalari: `PROJECT_AUDIT.md`. Har bir bosqich alohida branch va PR (squash merge).

## Topshiriq (2026-10-15, loyiha egasi)
Butun ilovani audit qilish va amalda tuzatish: UI/UX (yashil chaqnash, yagona dizayn), mahsulot nomlari, mahsulot rasmi,
kirimni tahrirlash (qoldiq ikki marta hisoblanmasin), mijoz boshlang'ich balansi, chek sozlamalari (preview, test cheki, 58/80 mm),
barcha modullar regressiyasi, testlar, yakuniy hisobot.

## Muhit
- Lokal stack: `docker compose up -d` (backend :8100, admin :3100, postgres :55432). Lokal sinov bazasida "Demo do'kon"
  (10 tovar, ega va kassir) — faqat lokal; parollar repoga yozilmaydi.
- Kassa: `cd apps/pos && flutter run -d windows`.

## Reja (bosqichlar)
| # | Bosqich | Holat |
|---|---|---|
| 1 | Audit (5 yo'nalish) → `PROJECT_AUDIT.md`, `docs/audit/` | ✅ T-100 |
| 2 | P0: yashil chaqnash, overflow, mijoz telefoni, noma'lum mijoz (T-100); sinxron yaxlitligi (T-101) | ✅ T-100, T-101 |
| 3 | Kirimni tahrirlash (teskari yozuv + yangi kirim, atomar) | ✅ T-102 |
| 4 | Mijoz boshlang'ich balansi | ✅ T-103 |
| 5 | Mahsulot rasmi (server + sinx + kassa) | ✅ T-105 |
| 6 | Chek sozlamalari (preview, logo, 58/80 mm, test cheki) | ✅ T-104a, T-104b |
| 7 | Vizual uslub va UX sayqali | ✅ T-106 |
| 8 | Regressiya, yakuniy hisobot | ✅ T-107 |

## Jurnal
### 2026-10-15
- Lokal backend konteyneri eski kod bilan yiqilgan edi (`ImportError: AppReleaseSerializer`) → `docker compose up -d --build backend admin`.
- Bo'sh lokal bazaga demo ma'lumot qo'shildi.
- Kassa ilovasi Windows'da ishga tushirildi. Logda: `RenderFlex overflowed by 4.0 pixels` — `apps/pos/lib/features/pos/widgets/product_panel.dart:147` (tez tugma kartasi, 2 qatorli nom + narx 88 px ga sig'maydi).
- 5 ta audit subagenti ishga tushirildi (faqat o'qish).

- Audit tugadi (5 hisobot `docs/audit/`). Asosiy topilmalar: yashil chaqnash sababi `PosScanFeedback` (oddiy bosishda ham, butun panel, fon bo'yalgan); server rad etgan tovar/mijoz savdolarni yo'qotadi; NUL belgisi sinxronni to'xtatadi; kirimni tahrirlash/bekor qilish yo'q; chekda preview/logo/STIR yo'q; rasm yo'q.
- T-100 tuzatishlari: chaqnash, overflow, telefon normallashtirish, noma'lum mijoz → pending. Testlar: backend to'liq yashil, pos 627, ui 134.

- T-101: noma'lum tovar → pending, ziddiyatli shtrix-kod tushiriladi, o'chirilgan bog'liqliklar qabul, yopiq smenaga kechikkan hodisa, NUL, nom tozalash/cheklovlar, qayta yuborish paytida pull yo'q. Backend to'liq yashil, pos 630.

- T-102: kirimni tahrirlash/bekor qilish (server `correct_receipt`/`cancel_receipt`, hodisalar, pull `features`; kassa drift v4, `ReceiptStore`, UI, tasdiqlash oynasi `showPosConfirm`). Golden'da topilgan xato: tasdiqlash oynasi qoldiqni yuklanmagan provider'dan olib "manfiy qoldiq" ko'rsatardi — bazadan o'qishga o'tkazildi. Backend 764, pos 661.

- T-103: `opening` qarz turi (± , bitta mijozga bitta, smenasiz), mijoz bilan bitta tranzaksiya/hodisada; avans — ega/menejer; hisobotda avans alohida; dizayn tizimiga `PosSegmentedControl`, `PosDateField`; kassada forma, kartada "Mijoz haqi (avans)". Tarjima-qoida testi qattiq yozilgan yorliqni ushladi — tuzatildi. Backend to'liq, pos 680.

- T-104a: chek yasovchi xatolari (to'lovlar = JAMI, Berildi/Qaytim, Summa, birlik, bo'sh qatorlar, telefon, belgilar, Ў/ў), ESC/POS profil (`FS .`, kod sahifasi, kesish/surish, baland JAMI), preview (printer bilan bir manba, Roboto Mono), test cheki = namuna chek, 42 belgi, qayta urinish NUSXA emas, pul qutisi avto-cheksiz ham. Golden'da topilgan: preview oxirgi belgini kesardi (mavzu `letterSpacing`) — token 0, regressiya testi. pos 704.

- T-104b: `Store` rekvizitlari (yuridik nom, STIR/JShShIR, logotip, ko'rsat/yashir), `store.upserted`, drift v5, o'z PNG/1-bit/`GS v 0`, muharrir + jonli chek. Golden'da topildi: logotip kengligi yaxlitlanish bilan 380 (384 o'rniga) — tuzatildi; desktop'da forma va chek yonma-yon emas edi — keng karta. pos 728, backend to'liq.

- T-105: server `ProductImage` (Pillow, JPEG 800/200, tenant view, media volume, zaxira), kassa drift v6, `product_images` navbati/kesh, `ProductImageSync` (outbox'dan alohida), tovar kartasi/ro'yxat/kassa qidiruvida rasm, `PosThumbnail`. Topilgan: tarmoq xatosida multipart fayl oqimi Windows'da faylni band qilardi — xotiradagi baytlarga o'tildi; saqlash tugmasi PIN kutilayotganda spinner ko'rsatardi — ajratildi. Backend to'liq, pos 743.

- T-106: holat qatori va telefon menyusi, ikki marta bosish/qotish, inventarizatsiya o'chirish tasdig'i, naqd qarz to'lovi faqat smenada, smena bazadan (eskirgan provider qiymati — haqiqiy xato), qisman tovar tahriri, pul maydoni formati, majburiy `*`, ro'yxat xato holati, dublikat nom, o'chirilgan tovar kartasi, bo'sh PLU. Sinab ko'rilgan va voz kechilgan: serverda "qisman tahrir yaratishdan oldin kelsa — kutish" qoidasi (kassa hodisalarni tartib bilan yuboradi; mavjud validatsiya testini buzardi). pos 754, ui 141, backend to'liq.

- T-107: to'liq regressiya (backend, kassa, dizayn tizimi, widgetbook, admin unit + e2e) — yashil; yakuniy hisobot `PROJECT_AUDIT.md` da.

## Keyingi qadam
- Foydalanuvchi qarorlari: `docs/QUESTIONS.md` (Q-003…Q-007, Q-009…Q-011), RC-B4; jismoniy printer va mobil qurilmada sinov.
