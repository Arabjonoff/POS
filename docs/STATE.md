# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-044 Chek chop etish
- Branch: feat/T-044-printing
- Boshlangan: 2026-10-15
- Oxirgi yangilanish: 2026-10-15

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. `apps/pos/lib/features/printing/receipt.dart`: `ReceiptData` (do'kon, chek raqami, vaqt, kassir, qatorlar, chegirma, jami, to'lovlar, qaytim, nasiya mijozi + qarz) va `ReceiptBuilder` (sof: 32/48 belgi → qatorlar) + `ReceiptLoader` (bazadan savdo bo'yicha) + snapshot testlar `test/printing/receipts/*.txt`
- [ ] 2. `escpos.dart`: ESC/POS kodlovchi (init, markaz, qalin, CP866 / UTF-8, kesish, pul qutisi impulsi) + testlar
- [ ] 3. Uzatish qatlami: `PrinterTransport` (tarmoq IP:9100 — dart:io Socket; Windows RAW — win32 winspool; soxta — test), `PrinterService` (savdo cheki, test chek, pul qutisi, oxirgi chek, holat) + testlar
- [ ] 4. Printer sozlamalari (`local_settings`: turi, manzil/printer nomi, kenglik, kodlash, avtomatik, nusxa, pul qutisi) + Sozlamalar ekranida "Printer" bo'limi (test chek) + tarjimalar
- [ ] 5. Kassaga ulash: yakunlashda avtomatik chek (xato savdoni to'xtatmaydi → "Chek chiqmadi" + "Qayta chop etish"), "Oxirgi chek" tugmasi, holat qatorida haqiqiy printer holati
- [ ] 6. Widget testlari + golden + skrinshotlar `docs/screenshots/T-044/`
- [ ] 7. Qaror `docs/decisions/` (Android Bluetooth/USB — alohida vazifa), spec, PR, CI → merge; ROADMAP, PROGRESS, STATE

## Oxirgi bajarilgan ish
- 1-qadam: `features/printing/receipt.dart` (`ReceiptData`, `ReceiptBuilder` → `ReceiptRow` lar, `render`, `PaperWidth`), `receipt_loader.dart` (`ReceiptLoader.load(saleId)`), testlar `test/printing/` (snapshot `receipts/*.txt`, yangilash `UPDATE_RECEIPTS=1`), tarjimalar `receipt*`.

## Keyingi aniq harakat
- 2-qadam: `apps/pos/lib/features/printing/escpos.dart` — `EscPosEncoder.encode(rows, {encoding, cut, openDrawer})` → `Uint8List`: ESC @, ESC a (markaz), ESC E (qalin), ESC t 17 (CP866) yoki UTF-8, GS V 66 0 (kesish), ESC p 0 25 250 (pul qutisi); CP866 da yo'q o'zbek kirill harflari (ў қ ғ ҳ) → у к г х. Test `test/printing/escpos_test.dart`.

## Eslatmalar
<!-- Keyingi sessiya bilishi kerak bo'lgan narsa: topilgan muammo, vaqtinchalik yechim, nima sinab ko'rildi va ishlamadi -->
- Bu kompyuterda 5432, 6379, 8000, 3000 portlari boshqa loyihalar (workers-*, mebel-*, twf-local-*) tomonidan band. Ularni to'xtatma! POS lokal portlari (.env): postgres 55432, redis 56379, backend 8100, admin 3100.
- `python` — Windows Store stub, `py -3.12` yo'q; `cd backend && uv run python` ishlat. Postgres'ga `localhost` emas, `127.0.0.1` orqali ulan (IPv6 osilib qoladi).
- Testlar `.env` ni o'qimaydi: `cd backend && DATABASE_URL=postgres://pos:pos@127.0.0.1:55432/pos uv run pytest`.
- 2026-10-14: elektr uzilishi `.git/config` ni nol baytlar bilan buzgan edi; foydalanuvchi qayta tikladi (`[core]` + `origin`).
- Docker Desktop o'chiq bo'lishi mumkin: `C:\Users\Muhammadi\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe` ni ishga tushir, `docker info` javob berguncha kut.
- Flutter: golden'lar `packages/ui/widgetbook/test/goldens/` da, qayta yaratish `make ui-goldens` (faqat Windows). Xatolarni ko'rish: `flutter test --no-pub -r failures-only`. Bash'da `sed -i` ba'zan "Device or resource busy" beradi (Windows) — Edit vositasini ishlat.
- Drift: build_runner "Tried to delete from package not in the build" bersa — `rm -rf apps/pos/.dart_tool/build` va qayta `dart run build_runner build`. Sxema o'zgarsa: `schemaVersion++`, `dart run drift_dev make-migrations`, `stepByStep` qadami.
- Flutter widget testida `tester.runAsync` + drift stream osilib qoladi — bazaga yozishni test tanasida to'g'ridan-to'g'ri `await` qil. Osilgan test: `flutter test --timeout 30s -r expanded`.
- API klient: `make api-clients` (backend sxema → admin TS + Dart: swagger_parser + build_runner `packages/api_client_dart`). Yangi endpoint kerak bo'lsa — `packages/api_client_dart/swagger_parser.yaml` `include_paths` ga qo'sh.
- Vaqt: ilova kodida `DateTime.now()` emas, `clock.now()` (package:clock) yoki `clockProvider` — widget testlarida soxta vaqt ishlashi uchun.
- Widget/golden testlarda telefonda (390×844) ekrandan pastdagi tugmani bosishdan oldin `tester.ensureVisible` — aks holda bosish pastki menyuga tushadi (ogohlantirish bilan, xatosiz).
- Testda `PosFormat.moneyAmount` oddiy probel emas — matnni `PosFormat` bilan yasab izla. `find.byType(TextField).first` orqadagi kassa qidiruvini topadi — `find.descendant(of: dialog, ...)`.
- Widget testi teardown'ida drift yozuvini kutma (`await notifier.flush()` addTearDown ichida) — test osilib qoladi (timeout ham ishlamaydi). Test tanasida kutish mumkin.
- To'lov oynasida skaner ro'yxatdan o'tgan: Flutter `HardwareKeyboard` ishlovchisi `true` qaytarsa ham hodisa `Focus.onKeyEvent` ga baribir yetadi. Shuning uchun oynada raqamlar faqat `onTyping` orqali (`MoneyInput(hardwareDigits: false)`), skaner Enter'i `_swallowEnter` bilan yutiladi.
