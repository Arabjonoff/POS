# Cheklar tarixi (T-109)

Loyiha egasi talabi (2026-10-15): yakunlangan cheklarni ko'rish va qayta chop etish uchun alohida bo'lim.

## Joylashuv
- Bo'lim **"Cheklar"** — menyuda "Kassa"dan keyin (ikon — chek). Tezkor tugma **Ctrl+7** (Ctrl+1…6 o'zgarmaydi — kassirlar odati),
  kassa ekranida **F7**. Telefonda — pastki panelda (7 bo'lim: nom faqat tanlanganida, `PosResponsiveScaffold` qoidasi).
- Hamma rol ko'radi (kassir ham): chek nusxasi va qaytarish huquqi o'zgarmaydi (qaytarish — menejer/ega tasdig'i, T-045).

## Ma'lumot
- Manba — **shu kassaning lokal bazasi** (`sales`, `sale_items`, `sale_payments`, `refunds`), oflayn ishlaydi. Boshqa kassa cheklari bu yerda
  yo'q (Q-006 bilan bir xil cheklov; tushuntirish matni ro'yxat ostida).
- Ro'yxat jonli (`watch`): yangi savdo yoki qaytarish darhol ko'rinadi.
- Qator: chek raqami (`D3-000123`), vaqt, kassir, mijoz (bo'lsa), pozitsiyalar soni, to'lov turlari (Naqd/Karta/Nasiya), JAMI,
  holat — "Qisman qaytarilgan" (sariq) / "Qaytarilgan" (qizil).
- Yuqorida jami: "N ta chek · S so'm", qaytarilgan bo'lsa "Qaytarilgan: R so'm" (summalar — sotuv JAMI; qaytarish alohida).

## Filtrlar
- **Sana:** "Bugun" (standart), "Kecha", "Sana" (tanlash; 1 kun). Kun — Toshkent vaqti bo'yicha 00:00–24:00.
- **Qidiruv:** chek raqami (qismi ham: `123`), mijoz ismi yoki tovar nomi. Qidiruvda matn bo'lsa sana filtri **qo'llanmaydi**
  (eski chekni raqami bilan topish), natija — oxirgi 200 ta.
- **Skaner:** chekdagi shtrix-kod (chek raqami) skanerlansa — o'sha chek darhol ochiladi; chek raqamiga o'xshash (`-` bor), lekin yo'q —
  "Chek topilmadi: …" xabari. Boshqa kod — qidiruvga tushadi. Tovar shtrix-kodi — shu tovar sotilgan cheklar (chekdagi kod bo'yicha).
- **To'lov turi:** Hammasi / Naqd / Karta / Nasiya (aralash to'lovli chek har bir turida ko'rinadi).

## Chek tafsiloti
- Keng ekranda (bo'lim kengligi ≥ 2 × 440 dp + oraliq; planshet 1024 va desktop) — o'ngda 440 dp panel; telefon va tor ekranda — ro'yxat
  o'rnida (orqaga tugmasi, Esc).
- Sarlavha: raqam, sana-vaqt, holat belgisi. **Chek ko'rinishi** — printerdagi chek bilan bir xil (`ReceiptPreview`, printer kengligi
  sozlamadan; sozlanmagan bo'lsa — standart 58 mm). Qaytarishlar bo'lsa — ro'yxat: vaqt, summa, usul (naqd/qarzdan), sabab.
- **"Qayta chop etish"** (asosiy tugma) — `printSale(copy: true)`: chekda "NUSXA". Natija xabari: "Printerga yuborildi" /
  "Chek chiqmadi" + "Qayta chop etish" / printer sozlanmagan — "Avval printerni sozlang" + "Sozlash" (Sozlamalar ochiladi). Ikki marta bosishdan
  himoya (yuborilayotganda tugma band).
- **"Qaytarish"** — qaytarish oynasi (F8) shu chek bilan ochiladi; to'liq qaytarilgan chekda tugma o'chiq.
- Klaviatura: Ctrl+P — qayta chop etish, Esc — tafsilotni yopish / qidiruvni tozalash. Yashirin bo'lim fokusni ushlab qolmaydi (kassa F-tugmalari ishlayveradi).

## Amalga oshirilishi
- `apps/pos/lib/data/sales/sale_history.dart` — `SaleHistory.watch(filter)` (savdolar, keyin bir so'rovda to'lov turlari, pozitsiyalar,
  qaytarilgan summa, kassir va mijoz nomlari; `sales`/`refunds`/`sale_payments` o'zgarsa qayta o'qiladi), `SaleHistoryFilter`, `saleHistoryProvider`.
- `apps/pos/lib/features/sales/sales_screen.dart` — bo'lim; `sale_detail.dart` — tafsilot.
- Testlar: `test/data/sale_history_test.dart`, `test/features/sales_history_test.dart`; golden `sales/*`.

## Boshqa kassa cheklari (T-110, Q-006 → A)
- Shu kassada yo'q **chek raqami** (`D2-000007` ko'rinishi) skanerlansa, qidiruvda Enter bosilsa yoki "Boshqa kassalardan qidirish"
  tugmasi bosilsa — internet bo'lsa serverdan olinadi (`GET /api/v1/sync/sales/?number=`, `sync-api.md`). Ro'yxatga qo'shilmaydi
  (lokal hisobot va smena buzilmasin) — faqat tafsilot ochiladi, "N-kassa cheki" belgisi bilan.
- Chek ko'rinishi — o'sha `ReceiptLoader.fromSource` (do'kon rekvizitlari, birliklar, qarz — lokal bazadan; kassir nomi — serverdan).
- **Qayta chop etish** — `PrinterService.printReceipt(copy: true)` (NUSXA, pul qutisi ochilmaydi).
- **Qaytarish** — qaytarish oynasi shu chek bilan; yoziladi odatdagidek (lokal tranzaksiya + outbox `refund.created`, `sale` — server
  savdosi id). Qaytarilgan miqdor = serverdagi + shu kassada qilingan, hali serverga yetmagan qaytarishlar (ikki marta qaytarilmasin).
  Qaytarishdan keyin chek serverdan qayta o'qiladi.
- Qaytarish oynasida (F8) ham: lokalda yo'q raqam → server.
- Oflayn: "Bu chek shu kassada yo'q. Boshqa kassa chekini ko'rish uchun internet kerak"; serverda yo'q — "Chek topilmadi: …";
  server xatosi — "Serverdan chekni olib bo'lmadi".
- Cheklov: ikki kassa bir vaqtda oflaynda bitta chekni qaytarsa — server ikkinchisini rad etadi (miqdor oshadi), outbox xatosi ko'rinadi.
- Lokal hisobotda boshqa kassa chekining qaytarilgan tannarxi 0 (savdo qatori lokalda yo'q); server hisoboti to'g'ri.
