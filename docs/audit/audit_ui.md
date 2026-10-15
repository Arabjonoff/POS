# POS (apps/pos + packages/ui) — UI/UX va dizayn tizimi auditi

Sana: 2026-10-15. Rejim: faqat o'qish (loyiha fayllari o'zgartirilmadi).
Ko'rilgan: `CLAUDE.md`, `docs/specs/design-system.md`, `docs/specs/pos-screen.md`, `docs/specs/barcode.md`,
`packages/ui/lib/**` (tema, tokenlar, komponentlar), `apps/pos/lib/**` (shell, features), ~20 ta golden skrinshot
(`docs/screenshots/T-030, T-041, T-042, T-043, T-044, T-050, T-052, T-053, T-060, T-070, T-085, ui-review`).

Ustuvorlik: **P0** — egasi aytgan xato / pul-ma'lumot yo'qolishi; **P1** — kundalik ishga sezilarli ta'sir; **P2** — sayqal.

---

## P0-1. "Element bosilganda butun ekran yashil chaqnaydi" — ILDIZ SABABI

### Qayerda
1. Chaqnash vidjeti — `packages/ui/lib/src/components/pos_scan_feedback.dart`
   - `:109` `Positioned.fill(...)` — overlay o'ralgan hududning **butun** maydonini egallaydi.
   - `:151` `color: color.withValues(alpha: 0.10 * opacity)` — butun hudud **yashil bilan to'ldiriladi** (faqat chet emas; doc-komment `:26` "hudud chetini chaqnatadi" deydi, kod esa to'liq fon ham bo'yaydi).
   - `:154` `width: 3` — qalin yashil ramka.
   - `:46` `_hold = 150 ms` + `:69` `PosMotion.overlay (200 ms)` = **350 ms** (qoida: animatsiya ≤ 200 ms).
   - Rang: `PosScanResult.success => p.successText` (`#15803D` yorug', `#22C55E` qorong'i — qorong'i fonda juda yorqin).
2. Chaqnash QAYERNI o'raydi (juda katta hudud):
   - `apps/pos/lib/features/pos/pos_screen.dart:720` — desktop/planshet: **butun o'ng panel** (savat, tablar, banner, JAMI, To'lash — ekranning 40 %i, to'liq balandlik).
   - `apps/pos/lib/features/pos/pos_screen.dart:817` — telefon: **qidiruv qatoridan JAMI paneligacha bo'lgan butun o'rta qism** (ekranning ~70 %i).
   - `apps/pos/lib/features/receiving/receipt_editor.dart:271` — Kirim tahrirlovchisi: **butun sahifa** (sarlavha, yetkazuvchi, qidiruv, qatorlar, footer).
   - `apps/pos/lib/features/inventory/count_editor.dart:162` — Inventarizatsiya: **butun sahifa**.
3. Chaqnash QACHON ishga tushadi — faqat skanerda emas, **har qanday bosishda**:
   - `pos_screen.dart:201-202` `_added()` → `_feedback.flash(PosScanResult.success)`. `_added()` `_pick()` ichida (`:198`) chaqiriladi, `_pick` esa
     tez tugma (QuickPanel, `:708`), qidiruv natijasi (`:702`, `:825`), klaviatura Enter (`_pickHighlighted`) va telefon tez tugmalar varag'idan chaqiriladi.
   - `pos_screen.dart:209` `_warn()` → sariq/qizil chaqnash ham bosishda (masalan, nofaol tovar tugmasi bosilsa).
   - `receipt_editor.dart:356-359` va `count_editor.dart:221-224` — qidiruv natijasini **bosish** → `_add()` → `_feedback.flash(success)` (`receipt_editor.dart:75`, `count_editor.dart:58`) → **butun sahifa** yashil.
4. Qo'shimcha (ikki marta chaqnash): `apps/pos/lib/features/pos/widgets/cart_panel.dart:245-249, 267-268` — qo'shilgan qator ham `successSoft` (yashil) fon bilan yonadi. Ya'ni bitta bosishda: panel to'liq yashil + qator yashil.

### Nega butun ekran yashil bo'ladi
Spec (`barcode.md:14`, `pos-screen.md:45`) "skaner → topildi → yashil chaqnash" deydi. Amalda `PosScanFeedback` sahifa/panel darajasida o'ralgan va `_added()`/`_add()` — skaner va qo'lda tanlash uchun **umumiy** funksiya. Shuning uchun kassir tovar tugmasini yoki qidiruv natijasini bosganda ham butun panel/sahifa 10 % yashil fon + 3 px yashil ramka bilan 350 ms davomida bo'yaladi. Telefonda va Kirim/Inventarizatsiyada bu deyarli butun ekran. Mavzu (`pos_theme.dart:93-96` splash/highlight/focus) aybdor EMAS — ular neytral/ko'k va past alfa.

### Ta'sir
Har bosishda ko'zni charchatuvchi "miltillash", tez ishlaganda (sekundiga 2–3 tovar) ekran doimiy yashil pulsatsiya qiladi; tasdiqlash signali ma'nosini yo'qotadi (skaner va bosish farqlanmaydi); epilepsiya/sezgirlik nuqtai nazaridan ham yomon; 200 ms qoidasi buzilgan.

### Tuzatish (taklif)
1. **Faqat skanerda chaqnatish.** `pos_screen.dart`: `_added({bool scanned = false})`; `flash` faqat `scanned == true` bo'lsa. `_onScan` → `_added(scanned: true)`, `_pick(..., barcode:)` dan kelganda ham `scanned: barcode != null`. Qo'lda bosishda — faqat qator yonishi (cart_panel) yetarli. `receipt_editor.dart:356` / `count_editor.dart:221` — `_add(product.id, flash: false)`.
2. **Hududni toraytirish.** `PosScanFeedback` ni butun panel/sahifa o'rniga faqat qidiruv maydoni (skaner kiritadigan joy) yoki savat ro'yxati ramkasiga o'rash. Kirim/Inventarizatsiyada — faqat qidiruv qatori + qatorlar ro'yxati, sarlavha/footer emas.
3. **Fonni olib tashlash.** `pos_scan_feedback.dart:151` — to'ldirishni olib tashlash (yoki alfa 0.04 gacha), faqat ramka (2 px). Doc-kommentga mos.
4. **Davomiylik ≤ 200 ms**: `_hold` 0–60 ms, fade `PosMotion.overlay - _hold` (jami ≤ 200 ms).
5. Ixtiyoriy: Sozlamalar → Skaner'da "Rang bilan ko'rsatish" (on/off) — `scanner_settings.dart` da `sound` yonida.

### Qanday sinash
- Widget test (`apps/pos/test/...pos_screen_test`): QuickPanel tugmasini `tester.tap` → `find.byType(PosScanFeedbackOverlay)` → opacity 0 / topilmaydi; `ScanListener` orqali skaner hodisasi → overlay bor.
- `packages/ui/test/components/feedback_components_test.dart`: overlay `BoxDecoration.color` null/shaffof ekanini va animatsiya `<= 200 ms` tugashini tekshirish (`tester.pump(200ms)` → yo'q).
- Qo'lda: Windows'da tez tugmani 10 marta ketma-ket bosish — ekran miltillamasligi; skaner bilan — faqat qidiruv/savat ramkasi qisqa yonishi. Kirim → qidiruv natijasini bosish — sahifa bo'yalmasligi.
- `make ui-goldens` (feedback galereyasi o'zgaradi) + `make pos-test`.

---

## P1 — muhim

### P1-1. Qoralamani (Kirim / Inventarizatsiya) tasdiqsiz o'chirish
- **Joy:** `apps/pos/lib/features/inventory/count_editor.dart:294-304` (`count-delete` ikon tugmasi **"Tasdiqlash" tugmasining yonida**, bir bosishda `deleteDraft`); `apps/pos/lib/features/receiving/receipt_editor.dart:164-167, 199-202, 234`.
- **Sabab:** tasdiq oynasi ham, "Bekor qilish" toast ham yo'q (spec: "xavfli amalda bitta tasdiq", "undo toast 5 s").
- **Ta'sir:** soatlab sanalgan inventarizatsiya yoki katta kirim bitta noto'g'ri bosishda yo'qoladi (telefonda tugmalar yonma-yon, 56 dp).
- **Tuzatish:** `showPosDialog` bilan tasdiq ("Qoralama o'chirilsinmi? N ta qator yo'qoladi"), danger variant tugma; yoki soft-delete + 5 s undo toast. "Qoralamani o'chirish" `ghost` (ko'k) tugmasini danger-ohangga o'tkazish.
- **Sinash:** widget test — `count-delete` bosilgach dialog ko'rinadi, "Bekor" → qoralama saqlanadi; "O'chirish" → o'chadi.

### P1-2. Saqlashda ikki marta bosish (double-submit) — tovar kartasi
- **Joy:** `apps/pos/lib/features/products/product_card.dart:231-262` — `_busy` faqat `await editor.validate(draft)` (asinxron, DB) va menejer tasdig'idan **keyin** `true` bo'ladi (`:262`).
- **Ta'sir:** "Saqlash"ni / Enter'ni tez ikki marta bosish → ikki parallel `_save` → **ikki xil UUID bilan ikki tovar** yaratilishi mumkin.
- **Tuzatish:** `_busy = true` ni funksiya boshida (validatsiyadan oldin) qo'yish va `finally` da qaytarish; yoki alohida `_validating` bayrog'i.
- **Sinash:** `validate` ni sekinlashtirilgan fake bilan; `tap` ×2 → `save` bir marta chaqirilganini tekshirish.

### P1-3. Kutilmagan xatoda tugma abadiy "yuklanmoqda" holatida qoladi
- **Joy:** `product_card.dart:263-273` (faqat `InvalidProductException`), `customer_card.dart:244-271` (faqat `PaymentExceedsDebtException`), `customer_card.dart:446-462` (try yo'q), `receiving_screen.dart:28-31`, `customers_screen.dart:41-52`, `shift_screen.dart:31-46` (smena yopish, try yo'q), `supplier_picker.dart:54-71`.
- **Ta'sir:** DB/kutilmagan xatoda spinner aylanib qoladi yoki hech narsa bo'lmaydi; foydalanuvchiga xabar yo'q, oynani faqat Esc bilan yopish mumkin.
- **Tuzatish:** har saqlashda `try { ... } on Exception { showPosToast(l10n.saveFailed, tone: danger) } finally { _busy = false }`. Umumiy helper (`runGuarded`) `features/common/` da.
- **Sinash:** store'ni xato tashlaydigan fake bilan almashtirib widget test: toast ko'rinadi, tugma yana faol.

### P1-4. Himoyasiz async tugmalar (ikki marta bosish)
- **Joy:** `receiving_screen.dart:28-31, 53` ("Yangi kirim" — ikki bosish = ikki bo'sh qoralama); `supplier_picker.dart:54-71, 139` (ikki yetkazuvchi); `shift_screen.dart:142` ("Smenani yopish" tugmasi yopish davomida faol); `inventory_screen.dart:31-70`; `receipt_editor.dart:164` (`_deleteDraft` — `_busy` o'rnatilmaydi).
- **Tuzatish:** `_busy` + `PosButton(loading: _busy, onPressed: _busy ? null : ...)` — `payment_dialog.dart` dagidek.
- **Sinash:** sekin fake store; ikki `tap` → bitta yozuv.

### P1-5. Telefonda holat qatori kesilgan — printer/smena ko'rinmaydi
- **Joy:** `packages/ui/lib/src/components/pos_status_bar.dart:53-65` (gorizontal `SingleChildScrollView`, scroll belgisi yo'q); `apps/pos/lib/app/shell/app_status_bar.dart:50-117`.
- **Dalil:** `T-042/cart_phone_dark.png`, `T-085/grace_phone_light.png`, `T-060/card_phone_light.png`, `ui-review/ru_pos_phone_light.png` — "Prin…/При…" kesilgan, "Smena" va xatolar umuman ko'rinmaydi.
- **Ta'sir:** CLAUDE.md qoidasi ("holat qatori doim ko'rinadi: internet, printer, smena, sinxronlanmagan") telefonda buzilgan.
- **Tuzatish:** compact rejimda faqat ikonlar (+ son), muammoli elementlar birinchi va matnli; yoki `Wrap`/ikki qator; OK holatlarni yashirish ("hammasi yaxshi" bitta ikon).
- **Sinash:** golden 390×844 — barcha 4 element ko'rinadi; ru tilida ham.

### P1-6. Telefonda pastki navigatsiyada 6 bo'lim — yozuvlar siqilgan
- **Joy:** `pos_responsive_scaffold.dart` `_BottomNav` (6 ta `AppSection`).
- **Dalil:** skrinshotlarda "Sozlamalar"/"Hisobotlar" chetga tegib, kichraytirilgan; ruschada "Настройки" kesiladi.
- **Tuzatish:** telefonda 4–5 bo'lim (Kassa, Tovarlar, Kirim, Mijozlar, "Yana" → Hisobotlar, Sozlamalar) yoki faqat tanlanganning yozuvi.
- **Sinash:** golden 360×800 va 390×844, uz/ru/uz-Cyrl — yozuv kesilmaydi.

---

## P2 — sayqal

### Rang palitrasi va vizual
- **P2-1. Yashil ortiqcha (doimiy holat qatori).** `app_status_bar.dart:34, 76, 100` — "Internet bor", "Printer ulangan", "Smena ochiq" doim `PosTone.success` (bold yashil). Har ekran pastida/tepasida 3 ta yashil yozuv → yashil "signal" qadrsizlanadi, chaqnash bilan birga ekran "yashil" ko'rinadi. **Tuzatish:** OK holat — neytral (`textSecondary`, w400), rang faqat muammoda (warning/danger). Golden'larni yangilash.
- Umumiy palitra yaxshi: neytral slate, bitta ko'k primary, katta to'yingan fonlar va gradientlar yo'q, soyalar yumshoq (2 daraja), radius 8/12/16 izchil. Qattiq yozilgan rang `apps/pos/lib` da **topilmadi** (`Color(0x`, `Colors.*` grep — 0). `TextStyle(`/`fontSize` — 0.
- **P2-2. Tanlangan savat qatori doim ko'k fon.** `cart_panel.dart:267-269` — oxirgi qator avtomatik `selected` → `primarySoft` + 2 px ramka (skrinshotlar: bitta tovar bo'lsa ham ko'k blok). Qo'shilish chaqnashi (`successSoft`) bilan ketma-ket rang almashadi (yashil→ko'k). **Tuzatish:** tanlovni faqat klaviatura fokusida ko'rsatish yoki fonni neytral `surfaceMuted` + chap chiziq.
- **P2-3. Kichik qattiq o'lchamlar (token emas):** `features/auth/lock_screen.dart:161` (200), `:194` (64), `:249` (56); `count_editor.dart:433` (120); `camera_scan_page.dart:93-97` (280×160, ramka 3); `settings_screen.dart:85`, `shift_screen.dart:183` (560), `open_shift_card.dart:67` (400); `reports_screen.dart:578` (`EdgeInsets.symmetric(horizontal: 2)`); `money_input.dart:141`, `qty_dialog.dart:140`, `discount_dialog.dart:212` (`width: 2`); `products_screen.dart:401-464` (ustun minWidth'lari). `packages/ui` ichida: `pos_button.dart:13` `xl(80, …, 22, …)`, shrift o'lchamlari 14/16/18/22 `PosTypography` o'rniga raqam. **Tuzatish:** `PosSizes.focusRing`, `PosSizes.formMaxWidth`, `PosSizes.avatarL/M` va h.k. tokenlar.
- **P2-4. Hisobotda tiyinli summa:** `T-070/today_phone_light.png` — "41 787,18 so'm" (`pos_format.dart:26-33`). Boshqa joylarda butun so'm. Hisobot KPI'larida yaxlitlangan ko'rinish (yoki vaznli tovar narxini so'mga yaxlitlash qarori) — biznes qarori, `QUESTIONS.md` ga.

### Tipografiya / formalar izchilligi
- **P2-5. Pul maydonlarida guruhlash yo'q:** Kirim (`T-052/editor_desktop_light.png`: "11000", "14000") va tovar kartasi ("15000") — xom raqam; kassa/to'lov oynasida esa "100 000 so'm" (`money_input.dart`). **Tuzatish:** barcha pul maydonlari `MoneyInput` / guruhlovchi formatter orqali.
- **P2-6. Yorliqlarda birlik nomuvofiq:** Kirim — "Tannarx", "Sotish narxi"; tovar kartasi — "Sotish narxi, so'm", "Tannarx, so'm". Bir xil qilish.
- **P2-7. Majburiy maydon belgisi yo'q:** `PosTextField` (`packages/ui/lib/src/components/pos_text_field.dart:10-31`) da `required` parametri yo'q; "Nomi" (tovar, mijoz, yetkazuvchi) faqat saqlashda `fieldRequired` xatosi bilan bilinadi. **Tuzatish:** `required: true` → yorliq yonida `*` yoki "(majburiy)", ixtiyoriylarga "(ixtiyoriy)".
- **P2-8. Ikki qator "Hammasi" filtri:** `T-050/list_desktop_light.png` — qoldiq filtri va kategoriya filtri ikkalasi "Hammasi" bilan, yorliqsiz. **Tuzatish:** qatorlar oldida kichik yorliq ("Qoldiq:", "Kategoriya:") yoki kategoriyani dropdown.
- **P2-9. Sozlamalar sarlavhasi ostida karta kesilgan:** `T-044/settings_desktop_light.png` — "Chek printeri" kartasi sarlavha ostida qisman yashiringan (scroll), keng ekranda kontent 560 px, o'ng tomon bo'sh. Ikki ustun (≥ 1280) yoki sticky sarlavha soyasi.
- **P2-10. "Qoralamani o'chirish" ko'k matnli tugma** (`receipt_editor.dart:199`, ghost/primaryText) — xavfli amal danger rangida bo'lishi kerak.

### UX holatlari
- **P2-11. Xato holati yo'q (abadiy spinner):** `receiving_screen.dart:~56` (`receipts == null` → spinner), shunga o'xshash `inventory_screen`, `customers_screen`, `products_screen` — `ref.watch(x).value` ishlatiladi; `AsyncError` bo'lsa `value == null` → spinner abadiy. **Tuzatish:** `.when(data:, loading:, error: → PosEmptyState(tone: danger, action: Qayta urinish))`.
- **P2-12. Skeleton o'rniga spinner:** spec "skeleton yuklanishda", lekin `apps/pos/lib` da 17 ta `CircularProgressIndicator`/`LinearProgressIndicator`, `PosSkeleton` — 1 marta. Ro'yxat ekranlarida `PosSkeletonListTile`.
- **P2-13. Qatorni o'chirishda undo yo'q:** `count_editor.dart:448-455`, `receipt_editor.dart:516` — darhol o'chadi (kassada esa undo toast bor — `pos_screen._remove`). Bir xil qilish.
- **P2-14. Yuklanayotgan tugma fokusni yo'qotadi:** `pos_button.dart:145-147` — `loading` da `ExcludeFocus` → klaviatura foydalanuvchisining fokusi yo'qoladi, keyin Tab boshidan. **Tuzatish:** `IgnorePointer` + `onPressed: null` qoldirib, fokusni saqlash (yoki tugagach fokusni qaytarish).
- **P2-15. Ikon takrori:** `app_status_bar.dart:91-104` — smena va soat farqi ikkalasi `Icons.schedule`; smena uchun `Icons.point_of_sale`/`lock_clock`.
- **P2-16. Telefonda qulflash/kassir ismi faqat Sozlamalarda:** `pos_responsive_scaffold.dart` `footer` faqat expanded. Telefon kassasida tez qulflash yo'q (avtomatik qulflash bor). Ixtiyoriy: holat qatorida qulf ikoni.

### Yaxshi tomonlar (o'zgartirmaslik kerak)
- Tokenlar va `PosPalette` izchil, WCAG AA juftliklari testlangan; `apps/pos` da qattiq rang/shrift yo'q.
- Asosiy pul oynalari (`payment_dialog`, `cash_movement_dialog`, `refund_dialog`, `customer_card` qarz to'lash, `receipt_editor._post`) `_busy` + `loading` bilan himoyalangan.
- Dialog tugmalari doim ko'rinadi (T-091), F-tugma yorliqlari tugmalarda, jami summa eng katta matn.
- Bo'sh holatlar ko'p ekranlarda bor (`PosEmptyState` 17 faylda).
