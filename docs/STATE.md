# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-082 Admin: mijozlar (tenantlar)
- Branch: feat/T-082-admin-tenants
- Boshlangan: 2026-10-15
- Oxirgi yangilanish: 2026-10-15

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [ ] 1. UI komponentlar (shadcn: dialog, table, tabs, label, textarea, select) + `src/lib/platform.ts` ga tenant funksiyalari, Server Actions (`src/app/(app)/tenants/actions.ts`: onboard, block, unblock, reset-password)
- [ ] 2. `/tenants` ro'yxati: qidiruv, holat filtri (URL), jadval, sahifalash, bo'sh/xato holatlari, CSV eksport
- [ ] 3. `/tenants/new` 3 qadamli usta (do'kon → ega (vaqtinchalik parol) → tarif + sinov) va natija kartasi (nusxa olish)
- [ ] 4. `/tenants/[id]`: tablar Umumiy (obuna, bloklash/blokdan chiqarish — sabab bilan), To'lovlar, Qurilmalar, Foydalanuvchilar (parol tiklash), Faollik
- [ ] 5. Soxta API (tenantlar, tariflar, qurilmalar, to'lovlar, foydalanuvchilar, hodisalar — xotirada) + Vitest + Playwright (yaratish → ro'yxatda → ega API orqali kira oladi; bloklash)
- [ ] 6. Spec, skrinshotlar, PROGRESS, ROADMAP, PR, merge

## Oxirgi bajarilgan ish
- Reja yozildi.

## Keyingi aniq harakat
- 1-qadam: `cd apps/admin && npx shadcn add dialog table tabs label textarea select`, so'ng `src/lib/platform.ts`.

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
- OpenAPI: yangi `type` enum qo'shilsa nom to'qnashadi — `backend/config/settings/base.py` ENUM_NAME_OVERRIDES ga qo'sh (aks holda mavjud enum nomi o'zgarib, eski generatsiya fayli qoladi).
- Dialog ichidagi TextEditingController'larni `showPosDialog` qaytgach darhol dispose qilma (yopilish animatsiyasi hali ishlatadi) — controller'lar dialogning o'z State'ida bo'lsin.
- Widget testi teardown'ida drift yozuvini kutma (`await notifier.flush()` addTearDown ichida) — test osilib qoladi (timeout ham ishlamaydi). Test tanasida kutish mumkin.
- To'lov oynasida skaner ro'yxatdan o'tgan: Flutter `HardwareKeyboard` ishlovchisi `true` qaytarsa ham hodisa `Focus.onKeyEvent` ga baribir yetadi. Shuning uchun oynada raqamlar faqat `onTyping` orqali (`MoneyInput(hardwareDigits: false)`), skaner Enter'i `_swallowEnter` bilan yutiladi.
- Generatsiya qilingan Dart klient `DateTime` query'ni to'liq ISO vaqt qilib yuboradi; server `DateField` (`YYYY-MM-DD`) bo'lsa — Dio bilan to'g'ridan-to'g'ri chaqir (`reports_provider.dart` misoli).
- Admin e2e lokal: `cd apps/admin && npm run build && E2E_PORT=3150 npx playwright test` (3100 — docker admin bo'lishi mumkin; reuseExistingServer uni qayta ishlatib yuboradi). Soxta Django API: `e2e/mock-api.mjs` (3199).
- Admin'ga npm paket qo'shilsa: Windows'dagi npm lock'dan `@emnapi/core|runtime` (optional, wasm) yozuvlarini o'chiradi va CI `npm ci` yiqiladi. Yechim: yozuvlarni main'dagi lock'dan qaytarish, `npm ci --dry-run` bilan tekshirish.
