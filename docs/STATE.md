# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-051 Excel/CSV import
- Branch: feat/T-051-import
- Boshlangan: 2026-10-15
- Oxirgi yangilanish: 2026-10-15

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 0. Spec `docs/specs/product-import.md` va qaror 0009 (server tomonda import)
- [x] 1. Backend: `openpyxl` (uv add), `apps/catalog/importing.py` — o'qish (xlsx/csv), sarlavhadan moslash taklifi, qator tahlili (pul, birlik, kategoriya, shtrix-kod), tekshirish va qo'llash (bitta tranzaksiya, bulk); `ProductImport` modeli + migratsiya
- [x] 2. Backend API (qurilma tokeni): template / upload / check / apply + pytest (5000 qator, xatolar, tenant/qurilma izolyatsiyasi, takroriy apply), OpenAPI + `make api-clients`
- [ ] 3. Kassa: `file_picker` bog'liqligi, `data/catalog/product_import.dart` (API o'rami, soxta bilan almashtiriladi), import oynasi (fayl → moslash → tekshirish → import → natija), shablonni saqlash, oflayn xabar, PIN; tarjimalar
- [ ] 4. Widget testlari + golden + skrinshotlar `docs/screenshots/T-051/`
- [ ] 5. PR, CI → merge; ROADMAP, PROGRESS, STATE

## Oxirgi bajarilgan ish
- 1–2-qadam: `apps/catalog/importing.py` (o'qish, moslash, tahlil, bulk qo'llash + ChangeLog), `ProductImport` (migratsiya 0003), `apps/sync/imports.py` (template/upload/check/apply), testlar `apps/sync/tests/test_product_import.py` (12, 5000 qator ham); OpenAPI + admin TS + Dart klient yangilandi.

## Keyingi aniq harakat
- 3-qadam: `apps/pos`: `flutter pub add file_picker` (ildizda `flutter pub get`), `lib/data/catalog/product_import.dart` (`ProductImportApi`: template baytlari — xom Dio, upload — `syncProductImportsCreate(file:)`, check/apply), `lib/features/products/import_dialog.dart` (bosqichlar), Tovarlar ekranida "Excel'dan yuklash".

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
