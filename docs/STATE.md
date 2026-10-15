# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-109 Cheklar tarixi va qayta chop etish (loyiha egasi talabi)
- Branch: feat/T-109-receipt-history
- Boshlangan: 2026-10-15
- Oxirgi yangilanish: 2026-10-15

## Qadamlar (vazifa ichida)
- [x] 1. Spec `docs/specs/receipt-history.md`, ROADMAP 12-bosqich T-109
- [x] 2. Ma'lumot: `lib/data/sales/sale_history.dart` (filtr, ro'yxat, jonli)
- [x] 3. Unit test `test/data/sale_history_test.dart`
- [x] 4. Bo'lim: `AppSection.sales` (kassadan keyin, Ctrl+7, kassada F7), router
- [x] 5. `lib/features/sales/sales_screen.dart` (filtrlar, ro'yxat, skaner) + `sale_detail.dart` (chek ko'rinishi, qayta chop etish, qaytarish)
- [x] 6. `showRefundDialog(saleId:)`; l10n (uz/uz-Cyrl/ru)
- [ ] 7. Widget testlar `test/features/sales_history_test.dart`, golden `sales/*`, boshqa golden'larni yangilash (menyuda yangi ikon)
- [ ] 8. Hujjatlar (pos-screen.md klaviatura, user guide), tekshiruvlar, PR, merge

## Oxirgi bajarilgan ish
- Bo'lim (`AppSection.sales`), `features/sales/sales_screen.dart` + `sale_detail.dart`, F7, `showRefundDialog(saleId:)`, l10n — analyze toza.
- Widget testlar (10) yashil. Ishlab turgan: `flutter test --update-goldens test/goldens` (menyuga ikon qo'shildi).

## Keyingi aniq harakat
- 7-qadam: `apps/pos/test/features/sales_history_test.dart` (seedSaleHistory + clockProvider=historyNow), keyin golden `sales/*` va boshqa golden'larni `--update-goldens`.

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
- Kassa golden'lari qo'shimcha `hd` (1366×768) va `fhd` (1920×1080) da (`kassaDevices`, `golden_helpers.dart`). Testda menyu bo'limi — `tapNav(tester, 'Sozlamalar')` (desktopda menyu yig'ilgan, nom tooltip'da). Ctrl+tugma — `pressCtrl`.
- Widget/golden testlarda telefonda (390×844) ekrandan pastdagi tugmani bosishdan oldin `tester.ensureVisible` — aks holda bosish pastki menyuga tushadi (ogohlantirish bilan, xatosiz).
- Testda `PosFormat.moneyAmount` oddiy probel emas — matnni `PosFormat` bilan yasab izla. `find.byType(TextField).first` orqadagi kassa qidiruvini topadi — `find.descendant(of: dialog, ...)`.
- OpenAPI: yangi `type` enum qo'shilsa nom to'qnashadi — `backend/config/settings/base.py` ENUM_NAME_OVERRIDES ga qo'sh (aks holda mavjud enum nomi o'zgarib, eski generatsiya fayli qoladi).
- Dialog ichidagi TextEditingController'larni `showPosDialog` qaytgach darhol dispose qilma (yopilish animatsiyasi hali ishlatadi) — controller'lar dialogning o'z State'ida bo'lsin.
- Widget testi teardown'ida drift yozuvini kutma (`await notifier.flush()` addTearDown ichida) — test osilib qoladi (timeout ham ishlamaydi). Test tanasida kutish mumkin.
- To'lov oynasida skaner ro'yxatdan o'tgan: Flutter `HardwareKeyboard` ishlovchisi `true` qaytarsa ham hodisa `Focus.onKeyEvent` ga baribir yetadi. Shuning uchun oynada raqamlar faqat `onTyping` orqali (`MoneyInput(hardwareDigits: false)`), skaner Enter'i `_swallowEnter` bilan yutiladi.
- Generatsiya qilingan Dart klient `DateTime` query'ni to'liq ISO vaqt qilib yuboradi; server `DateField` (`YYYY-MM-DD`) bo'lsa — Dio bilan to'g'ridan-to'g'ri chaqir (`reports_provider.dart` misoli).
- Push'dan oldin: `dart format apps/pos/lib apps/pos/test packages/ui/lib packages/ui/test packages/ui/widgetbook/lib packages/ui/widgetbook/test` (CI tekshiradi); backend serializer o'zgarsa — `make schema` (openapi.yaml diff CI'da).
- Windows'da Python bilan fayl yozganda `newline=''` ishlat (aks holda CRLF); `\n`/`\u02bb` kabi escape'lar heredoc ichida buziladi — Edit vositasi yoki skript fayl ishlat. Ruff RUF001: o'zbek `ʻ` uchun `# noqa: RUF001`.
- Chek ko'rinishi (preview) mavzudan `letterSpacing` olsa oxirgi belgini kesadi — `PosTypography.receipt` da 0 (test: `receipt_preview_test.dart`).
- Widget/golden testda haqiqiy rasm (FileImage) yuklash `runAsync` + drift bilan osiladi — golden'da placeholder, rasm mavjudligi `PosThumbnail.image != null` bilan tekshiriladi. Fayl IO (rasm) sinxron — fake async'da osilmasin.
- Admin e2e lokal: `cd apps/admin && npm run build && E2E_PORT=3150 npx playwright test` (3100 — docker admin bo'lishi mumkin; reuseExistingServer uni qayta ishlatib yuboradi). Soxta Django API: `e2e/mock-api.mjs` (3199).
- Admin'ga npm paket qo'shilsa: Windows'dagi npm lock'dan `@emnapi/core|runtime` (optional, wasm) yozuvlarini o'chiradi va CI `npm ci` yiqiladi. Yechim: yozuvlarni main'dagi lock'dan qaytarish, `npm ci --dry-run` bilan tekshirish.
- Admin skrinshotlari: scratchpad'dagi `shots8x.cjs` naqshi — `node e2e/mock-api.mjs` + `API_URL_INTERNAL=http://127.0.0.1:3199 npx next start -p 3150`, keyin Playwright skript (`require(<apps/admin>/node_modules/playwright)`). Bash'da murakkab `node -e` / heredoc'ga `${...}` va qo'shtirnoq aralashsa buziladi — Write vositasi bilan fayl yoz.
- Next (admin): `"use client"` fayldan eksport qilingan qiymat (massiv, obyekt) server komponentda client reference bo'ladi — umumiy konstantalarni oddiy modulga qo'y.
- Flutter: bo'lim (StatefulShellRoute) almashganda fokus yo'qoladi — qaytganda ekran o'zi fokusni olishi kerak (`TickerMode.valuesOf` o'zgarishi, kassa misoli). Oyna mazmuni suriladi — testda pastdagi elementni bosishdan oldin `ensureVisible`.
- Prod stack lokal sinovi: `.env.prod.local` (CADDY_TLS=tls internal, 18080\/18443) + `docker compose -f docker-compose.prod.yml --env-file .env.prod.local -p pos-prodtest up -d --build`; curl `--resolve api.localhost:18443:127.0.0.1`. Git Bash'da `docker ... /deploy/x.sh` uchun `MSYS_NO_PATHCONV=1`. Admin→Django so'rovlari Content-Length bilan bo'lishi shart (WSGI chunked'ni o'qimaydi).
- Windows o'rnatuvchi lokal: `powershell -ExecutionPolicy Bypass -File apps/pos/tool/build-windows-installer.ps1 -ApiUrl ...`; jim sinov: `dist\kassa-setup-X.exe /VERYSILENT /CURRENTUSER /DIR=%TEMP%\kassa-test`, so'ng `unins000.exe /VERYSILENT`.
- Drift jonli oqimini `async*` + `await for (tableUpdates)` bilan yozma: obunani bekor qilish osilib qoladi (test timeout). `customSelect('SELECT 1', readsFrom: {...}).watch().asyncMap(...)` ishlat (`sale_history.dart`).
