# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-042 Kassa ekrani — savat
- Branch: feat/T-042-cart
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. Transliteratsiya (`core/text/translit.dart`) + pull'da `searchKey` + `ProductCatalog` (`data/catalog/product_catalog.dart`: shtrix-kod, vaznli kod/PLU, qidiruv nom/shtrix-kod boshi/PLU, tez tugmalar) + unit va tezlik testi (3000 tovar < 50 ms)
- [x] 2. Savat modeli va `CartController` (`features/pos/cart/`): qo'shish (+1, vaznli — yangi qator), miqdor, o'chirish + undo, qator/chek chegirmasi, 5 ta chek (slot), `cart_drafts` ga avto-saqlash va tiklash + unit testlar
- [x] 3. Chegirma huquqi: kassir uchun maksimal foiz (lokal sozlama), oshsa — menejer/ega PIN tasdig'i; `docs/QUESTIONS.md` Q-005
- [x] 4. Kassa ekrani UI (desktop/planshet): qidiruv + natijalar, tez tugmalar (kategoriya tablari), savat paneli (qatorlar, stepper, JAMI, To'lash), chek tablari
- [x] 5. Telefon maketi: qidiruv + kamera, savat, yopishqoq JAMI + To'lash paneli, tez tugmalar varag'i
- [ ] 6. Klaviatura va skaner: F1/F2/F3/F6/F12/Delete/↑↓/Esc, `ScanListener` + `onTyping`, chaqnash/signal, "Bu kod bazada yo'q"
- [ ] 7. Widget testlari (+ ilova qayta ochilganda savat tiklanishi)
- [ ] 8. Golden + skrinshotlar `docs/screenshots/T-042/`
- [ ] 9. To'liq tekshiruv, PR, CI → merge; ROADMAP, PROGRESS, STATE

## Oxirgi bajarilgan ish
- 4–5-qadam: `features/pos/pos_screen.dart` (`CashierView`: ikki panel ≥ 720 px, telefon — bir ustun + varaq), `widgets/cart_panel.dart`, `widgets/product_panel.dart`, `widgets/qty_dialog.dart`, `widgets/discount_dialog.dart`. Klaviatura (`_onKey`, HardwareKeyboard) va skaner (`ScanListener`) ham yozilgan — testlari 7-qadamda. `PosScanFeedback` (packages/ui) dispose xatosi tuzatildi. Golden: `test/goldens/pos_golden_test.dart` (+ `test/helpers/catalog_seed.dart`).

## Keyingi aniq harakat
- 6–7-qadam: `test/features/pos_screen_test.dart` — skaner (tez kiritish 10 ms + Enter → savatga), topilmagan kod, nofaol, vaznli kod, F1/F2/F3/F6/Delete/↑↓/Esc, qidiruv + Enter, undo, chegirma + menejer PIN, ilova qayta ochilganda savat. Keyin barcha golden'larni yangilash (`--update-goldens test/goldens`).

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
- Widget testi teardown'ida drift yozuvini kutma (`await notifier.flush()` addTearDown ichida) — test osilib qoladi (timeout ham ishlamaydi). Test tanasida kutish mumkin.
