# Kassa ekrani

## Maket
**Desktop/planshet (≥ 900 px):**
- Chap (60%): yuqorida qidiruv (F1), ostida tez tugmalar paneli (kategoriyalar tablari + shtrix-kodsiz tovarlar plitkalari: non, tuxum, sabzavot), qidiruv natijalari shu joyda ochiladi.
- O'ng (40%): savat — qatorlar (nom, miqdor stepper, narx, jami), pastda: mijoz (F4), chegirma, **JAMI** (eng katta matn), katta **To'lash (F12)** tugmasi.
- Yuqorida holat qatori: do'kon, kassir, smena, internet, printer, navbatdagi yozuvlar soni, vaqt.
- Savat tablari: "Chek 1 · Chek 2 · +" (kechiktirilgan cheklar, max 5).

**Telefon (< 600 px):** yuqorida qidiruv + kamera tugmasi; o'rtada savat; pastda yopishqoq panel: JAMI + To'lash. Tez tugmalar — alohida varaq (sheet).

## Asosiy oqim
1. Skanerlash (yoki qidiruv/tez tugma) → savatga.
2. F12 / To'lash → to'lov oynasi.
3. Naqd: olingan summa (tez tugmalar: Aniq, 50 000, 100 000, 200 000, raqamli klaviatura) → qaytim katta yashil raqam → Enter = yakunlash. Karta: bitta bosish. Nasiya: mijoz tanlash → tasdiqlash. Aralash: summalarni bo'lish.
4. Yakunlash → chek chop etiladi (sozlamaga ko'ra), savat tozalanadi, "Savdo yakunlandi · Qaytim 3 000 so'm" xabari 3 s, fokus yana skanerga.

## Savat qatori
- Miqdor: +/− tugmalari, bosib raqam kiritish (F2 — tanlangan qator miqdori), vaznli tovarda kg kiritish (0,250).
- Qatorni o'chirish: chapga surish (telefon) yoki Delete. Bekor qilish (undo) toast'i 5 s.
- Narxni o'zgartirish faqat huquq bilan (menejer PIN).
- Chegirma: qatorga yoki butun chekka, % yoki summa; huquq va maksimal foiz sozlamada.

## Tezlik talablari
- Skanerdan savatda paydo bo'lishigacha ≤ 100 ms.
- Qidiruv: har belgi kiritilganda ≤ 50 ms (3000–10 000 tovar), nom, shtrix-kod boshi, PLU bo'yicha; lotin/kirill farqi yo'q (transliteratsiya indeksi).

## Holatlar
- Smena ochilmagan → savat o'rnida "Smenani oching" kartasi va katta tugma.
- Readonly obuna → To'lash tugmasi o'chiq, sabab yozilgan banner.
- Bo'sh savat → "Tovarni skanerlang yoki qidiring" + skaner ikonasi.
- Printer ulanmagan → savdo davom etadi, holat qatorida qizil nuqta, yakunlashda "Chek chiqmadi, qayta chop etish" tugmasi.

## Klaviatura (Windows)
F1 qidiruv · F2 miqdor · F3 chegirma · F4 mijoz · F6 kechiktirish/yangi chek · F8 qaytarish · F9 pul kiritish/chiqarish · F12 to'lash · Esc bekor/yopish · Enter tasdiq · Delete qatorni o'chirish · ↑/↓ savat qatorlari.
Tezkor tugmalar ekranda kichik yorliq sifatida ko'rinadi (desktopda).

## Kassada amalga oshirilishi (T-042)
- **Katalog indeksi** — `data/catalog/product_catalog.dart`: tovarlar xotirada (`productCatalogProvider`, pull'dan keyin qayta quriladi). Shtrix-kod (har qanday kodi), tarozi kodi → PLU + vazn/narx, qidiruv (nom — lotin/kirill farqsiz `SearchKey.of`, so'zlar istalgan tartibda; shtrix-kod boshi ≥ 3 raqam; aniq PLU). Tartib: aniq kod → nom boshi → so'z boshi → ichida. 10 000 tovarda har belgi < 50 ms (test).
- **Qidiruv kaliti** — `core/text/search_key.dart`: kichik harf, kirill → o'zbek lotin (`ў`→`o`, `ғ`→`g`, `ч`→`ch`, `х`/`ҳ`→`x`), tutuq belgilari olib tashlanadi, `h` = `x`. Pull `products.search_key` ga ham shu yoziladi.
- **Savat** — `features/pos/cart/`: `Cart`/`CartLine`/`Discount` (pul — tiyin, miqdor — `qty_milli`), `CartController` (dona tovar qayta qo'shilsa +1, vaznli/tarozi — yangi qator; o'chirish + undo; qator va chek chegirmasi; 5 ta chek). Har o'zgarish navbat bilan `cart_drafts` ga yoziladi (v3: `discount_json`) — ilova o'ldirilsa ham tiklanadi.
- **Chegirma huquqi** — `discount_policy.dart`: kassir lokal sozlama `discount_cashier_max_bp` gacha (standart 5%, Q-005), undan katta — menejer/ega PIN (`features/common/manager_approval.dart`), tasdiqlagan `Discount.approvedBy` → savdoning `approved_by`.
- **Ekran** — `features/pos/pos_screen.dart`: kontent ≥ 720 px — ikki panel (chap 60%: qidiruv + natijalar yoki tez tugmalar kategoriya tablari bilan; o'ng 40%: chek tablari, qatorlar, chegirma, JAMI, To'lash); tor ekran — bir ustun, tez tugmalar varaqda, pastda yopishqoq JAMI + To'lash, qatorni chapga surib o'chirish. Planshetdagi tor savatda qator boshqaruvi alohida qatorga tushadi.
- **Klaviatura** — `HardwareKeyboard` ishlovchisi, faqat fokus kassa ekranida bo'lsa (oyna ochiq — yo'q): F1 qidiruv, F2 miqdor, F3 chegirma, F6 yangi chek, F12 to'lash, Delete qatorni o'chirish (qidiruvda matn bo'lsa — matnni), ↑/↓ natijalar yoki savat qatorlari, Enter — tanlangan natija, Esc — qidiruvni tozalash/tanlovni olib tashlash. F4 mijoz — T-043, F8 — T-045, F9 — T-046.
- **Skaner** — `ScanListener` (oyna ochiq paytda `enabled: false` — raqamlar oynaga tushadi). Topildi → savatga, yashil chaqnash + signal; topilmadi — "Bu kod bazada yo'q"; nofaol/narxi 0 — ogohlantirish; nazorat raqami xato — "Kod noto'g'ri o'qildi". Fokussiz yozilgan matn qidiruvga tushadi. "Tovar qo'shish" tez formasi — tovar kartasi bilan (keyin).
- **To'lash** — savdo to'xtagan bo'lsa (`salesBlockProvider`) tugma o'chiq va savat ustida sabab banneri. To'lov oynasi — quyida (T-043).

## Kassada amalga oshirilishi (T-043)
- **To'lov modeli** — `features/pos/payment/payment_draft.dart`: `PaymentDraft` (naqd / karta / nasiya / aralash; pul — tiyin). Naqd: `receivedTiyin == null` — "Aniq". Aralash: karta + nasiya kiritiladi, qolgani naqd (aniq). Xatolar: naqd yetmaydi, qismlar jamidan oshdi, nasiyada mijoz yo'q.
- **Yakunlash** — `checkout.dart`: savat + to'lov → `SaleWriter.complete` — **bitta SQLite tranzaksiyasi** (savdo, qatorlar, to'lovlar, qoldiq, qarz daftari, outbox). Xato bo'lsa hech narsa yozilmaydi, savat joyida qoladi, oynada "Savdoni saqlab bo'lmadi".
- **Oyna** — `payment_dialog.dart` (`showPaymentDialog`): Jami, tablar Naqd/Karta/Nasiya/Aralash. Naqd: Aniq, 50 000, 100 000, 200 000 (jamidan kichigi o'chiq), raqamli klaviatura; ko'rsatilgan "Aniq" summa birinchi raqam bilan almashtiriladi; qaytim — katta yashil, yetmasa — qizil "Yetmaydi". Telefonda naqdda ekran klaviaturasi yopiq (summaga bosilsa ochiladi) — qaytim va "Yakunlash" aylantirmasdan ko'rinadi. Enter = yakunlash, Esc = bekor (savat o'zgarmaydi).
- **Nasiya** — mijoz qidiruvi (ism lotin/kirill farqsiz, telefon raqamlari) va "Yangi mijoz" (ism + telefon, `customer.upserted` outbox). Mijoz balansi = qarz daftari yig'indisi. `balans + summa > limit` → ogohlantirish; yakunlashda menejer/ega PIN (`requestManagerApproval`), tasdiqlagan → savdoning `approved_by`.
- **F4** — chek mijozi (`showCustomerDialog`): savat ostida "Mijoz (F4)" tugmasi va olib tashlash; nasiyada shu mijoz oldindan tanlangan.
- **Skaner** — oyna ochiq paytda o'z `ScanListener` i: skan → "Avval to'lovni yakunlang" (oyna ichida, 3 s) va ovoz; skaner Enter'i savdoni yakunlamaydi. Flutter'da `HardwareKeyboard` ishlovchisi hodisani olsa ham u fokusdagi `Focus.onKeyEvent` ga baribir yetadi — shuning uchun oynada raqamlar faqat skaner xizmatining `onTyping` i orqali kiradi (`MoneyInput(hardwareDigits: false)`).
- **Natija** — oyna yopiladi, joriy chek bo'shaydi (`CartController.clearActive`), 3 s "Savdo yakunlandi · Qaytim 3 000 so'm", fokus yana skanerga. Chek chop etish — T-044.

## Kassada amalga oshirilishi (T-045 — qaytarish)
- **F8** yoki "Qaytarish" ikoni (desktopda qidiruv qatorida, telefonda chek tablari yonida) → `features/refunds/refund_dialog.dart`.
- **Savdoni topish**: chek raqami (katta-kichik harf farqsiz), chekdagi shtrix-kod (CODE128, T-044 chekining pastida; skaner Enter'i qaytarishni boshlamaydi) yoki "Oxirgi cheklar" ro'yxati (holati bilan: qisman / to'liq qaytarilgan). Faqat **shu kassaning lokal bazasidagi** savdolar topiladi (Q-006).
- **Qatorlar**: qaytarish mumkin bo'lgan miqdor (sotilgan − oldin qaytarilgan), − / + (dona — 1, vaznli — 0,100 kg), qiymatga bosilsa aniq miqdor kiritiladi, "Hammasini" tugmasi. To'liq qaytarilgan chek — "Bu chek to'liq qaytarilgan".
- **Summa** — `data/refunds/refund_calculator.dart`, server `record_refund` bilan aynan bir xil: qator — `mulDivHalfUp(qator jami, qty, sotilgan)`, qatorning oxirgi qismi — qoldiq; jami — chek chegirmasidan ulush ayiriladi, savdo to'liq yopilsa — `savdo jami − oldingi qaytarishlar`.
- **Sabab** (majburiy): Sifatsiz / Muddati o'tgan / Mijoz fikridan qaytdi / Xato urilgan va/yoki matn. **Usul**: naqd berish; savdoda nasiya qismi yetarli bo'lsa — "Qarzdan ayirish".
- **Huquq**: kassir bo'lsa — menejer/ega PIN (`requestManagerApproval`); menejer yoki ega o'zi bo'lsa, qayta PIN so'ralmaydi (`approved_by` — o'zi).
- **Yozish** — `refund_writer.dart`, bitta tranzaksiya: Refund + RefundItem + `StockMovement(refund, +qty)` + (qarzdan bo'lsa) `DebtEntry(refund, −summa)` + `sales.status` (`partially_refunded` / `refunded`) + outbox `refund.created`. Natija xabari: "Qaytarildi · Mijozga 4 000 so'm bering" yoki "Qaytarildi · Qarzdan … ayirildi". Smena X/Z hisobotida naqd qaytarishlar kutilgan naqddan ayiriladi (T-041).

## Kassada amalga oshirilishi (T-108b — tovar kartalari, qaror 0014)
- **Chap panel** (`widgets/product_panel.dart` → `ProductGrid`): qidiruv qatori (Qaytarish F8 va Smena — tor panelda faqat ikon), kategoriya tablari (48 dp, gorizontal suriladi, rangli nuqta), tovar kartalari panjarasi — `auto-fill, minmax(160, 1fr)`, karta 112 dp (`PosProductTile`).
- **Tablar:** "Sevimlilar" birinchi (tez tugmali tovarlar + shu kassada so'nggi 30 kunda eng ko'p sotilgan 24 ta, `topSellersProvider`), keyin "Hammasi" va faol tovari bor kategoriyalar. "Sevimlilar" bo'sh bo'lsa — "Hammasi". Kategoriya rangi — `PosPalette.categoryAccent(tartib)` (8 ta, AA), bazada maydon yo'q.
- **Karta:** rasm yoki bosh harf, nom (2 qator), narx qalin + `so'm/dona`, qoldiq. Kam (`min_stock` dan past) — sariq "Kam"; qoldiq ≤ 0 — kulrang karta, bosilsa baribir qo'shiladi va ogohlantiradi ("qoldiqda yo'q — chekka qo'shildi"). Do'kon qoldiq yuritmasa (hech bir tovarda musbat qoldiq yo'q) — qoldiq umuman ko'rsatilmaydi.
- **Qidiruv** panjarani jonli filtrlaydi (nom/shtrix-kod/PLU, hamma tovardan; tab tanlanmagan), ↑/↓ — kartani tanlaydi (ko'rinishga suriladi), Enter — qo'shadi; tab bosilsa qidiruv tozalanadi.
- **Topilmadi:** skanerlangan kod bazada yo'q — chap panelda qizil xabar "Tovar topilmadi: 4780001234567", xato ovozi, "Yangi tovar qo'shish" (tovar kartasi shu kod bilan; saqlansa — darhol chekka) va yopish (Esc). Keyingi skan xabarni olib tashlaydi.
- Telefonda: qidiruv natijasi — ro'yxat; tovar kartalari — varaqda (`ProductGrid`).
