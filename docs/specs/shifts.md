# Smena va kassa puli

- Smena = bitta qurilma + bitta kassir sessiyasi. Ochilmaguncha savdo yo'q.
- Ochish: boshlang'ich naqd (oldingi smenadan qolgan summa taklif qilinadi).
- Pul kiritish/chiqarish: summa + sabab (inkassatsiya, xarajat, ...).
- X hisobot (smena yopilmasdan): savdolar soni, to'lov turlari bo'yicha summa, qaytarishlar, kiritish/chiqarish, kutilayotgan naqd.
- Yopish: sanalgan naqd → farq (ortiqcha/kam) ko'rsatiladi → Z hisobot (ekran + chek) → smena yopiladi.
- Kassir almashganda: yopish va yangi ochish (yoki sozlamada "smena qurilmaga bog'liq, kassirlar PIN bilan almashadi").

## Kassada amalga oshirilishi (T-046 — kassa puli, hisobot cheki)
- **Kassa puli**: kassa ekranida F9 yoki smena sahifasidagi "Kassa puli harakatlari" kartasida "Pul kiritish" / "Pul chiqarish" → `features/shift/cash_movement_dialog.dart`. Oynada turi, summa (`MoneyInput`), sabab (Inkassatsiya / Xarajat / Mayda pul va/yoki matn, majburiy) va "Kassada: …" (kutilgan naqd) ko'rinadi.
- **Yozish** — `ShiftService.moveCash`, bitta tranzaksiya: `cash_movements` + outbox `cash.moved` `{id, shift, type: in|out, amount_tiyin, reason, by, at}` (`sales-api.md`). Faqat ochiq smenaga yoziladi. **Chiqarish kutilgan naqddan oshmaydi** ("Kassada faqat … bor") — ortiqcha nol bilan xato kiritilgan summa kassani minusga tushirmasin.
- **Hisobot**: X/Z da "Kassa puli: kiritilgan / olingan"; kutilgan naqd = boshlang'ich + naqd savdo − naqd qaytarish + kiritilgan − olingan + naqd qarz to'lovlari. Smena sahifasida harakatlar ro'yxati: vaqt, sabab, ±summa.
- **Hisobot cheki**: smena sahifasida X va Z uchun "Chek chiqarish" (`ReceiptBuilder.buildShift`, `PrinterService.printShiftReport`). Chekda: do'kon, X/Z, ochilgan/yopilgan (X da chop etilgan) vaqt, kassir, ekrandagi hisobotning barcha bo'limlari, Z da sanalgan naqd va farq. Snapshot: `apps/pos/test/printing/receipts/shift_*.txt`.
