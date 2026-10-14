# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-041 Smena ochish/yopish
- Branch: feat/T-041-shifts
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. ShiftService (open/close/report, X/Z) + unit testlar — `apps/pos/lib/data/shifts/shift_service.dart`
- [x] 2. UI: OpenShiftCard, ShiftScreen (/pos/shift), ShiftReportView, MoneyInput, tarjimalar (uz/uz-Cyrl/ru); analyze toza
- [x] 3. Widget testlar: smena yopiq → karta; ochish; X hisobot; yopish → farq → Z hisobot — `apps/pos/test/features/shift_test.dart`
- [ ] 4. Golden testlar + skrinshotlar (390×844, 1024×768, 1440×900) — `docs/screenshots/T-041/`
- [ ] 5. To'liq tekshiruv: `make pos-analyze pos-test ui-test`
- [ ] 6. PR, CI yashil → squash merge; ROADMAP `[x]`, PROGRESS, STATE tozalash

## Oxirgi bajarilgan ish
- 3-qadam: `test/features/shift_test.dart` (4 test). MoneyInput bir kadrda bir nechta tugmada raqam yo'qotardi — ichki holat bilan tuzatildi. Holat qatoridagi smena belgisi endi shu qurilma smenasi (`shiftOpenProvider` → `ShiftService.watchCurrentShift`).

## Keyingi aniq harakat
- `apps/pos/test/goldens/shift_golden_test.dart` (ochish kartasi, X hisobot, yopish dialogi, Z hisobot) + `flutter test --update-goldens test/goldens` (app_shell pos golden'lari "Smena" tugmasi tufayli yangilanadi); skrinshotlarni `docs/screenshots/T-041/` ga nusxalash.

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
