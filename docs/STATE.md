# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-043 To'lov oynasi
- Branch: feat/T-043-payment
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-15

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. To'lov modeli `apps/pos/lib/features/pos/payment/payment_draft.dart` (naqd/karta/nasiya/aralash, olingan, qaytim, qoldiq, `SalePaymentInput` lar) + unit testlar
- [x] 2. Mijozlar: `apps/pos/lib/data/customers/customer_directory.dart` (qidiruv, balans = Σ debt_entries, tez yaratish + `customer.upserted` outbox, limit tekshiruvi) + testlar
- [x] 3. `Checkout` (`features/pos/payment/checkout.dart`): savat + to'lov → `SaleWriter.complete` (bitta tranzaksiya) → savat tozalanadi; atomarlik testi
- [x] 4. To'lov oynasi UI (`features/pos/payment/payment_dialog.dart`): Naqd (Aniq/50 000/100 000/200 000, klaviatura, katta yashil qaytim, Enter), Karta, Nasiya (mijoz tanlash/yaratish, limit → menejer PIN), Aralash; oyna ochiqda skaner → "Avval to'lovni yakunlang"
- [x] 5. Kassa ekraniga ulash: F12, F4 mijoz (savatga), yakunlash xabari 3 s "Savdo yakunlandi · Qaytim …", fokus skanerga
- [x] 6. Widget testlari (3 harakat: skan → F12 → Enter; qaytim; karta; nasiya + limit; aralash; skaner bloklangan) + golden + skrinshotlar `docs/screenshots/T-043/`
- [ ] 7. To'liq tekshiruv, PR, CI → merge; ROADMAP, PROGRESS, STATE

## Oxirgi bajarilgan ish
- 6-qadam: 12 widget testi (`test/features/payment_test.dart`), goldenlar `pay_cash`/`pay_debt` (+ savat goldenlari mijoz qatori bilan yangilandi), skrinshotlar `docs/screenshots/T-043/`. Telefonda naqdda ekran klaviaturasi yopiq (summaga bosilsa ochiladi).

## Keyingi aniq harakat
- 7-qadam: `cd apps/pos && flutter analyze && flutter test`, `make ui-test`; `docs/specs/pos-screen.md` ga "Kassada amalga oshirilishi (T-043)" bo'limi; PR `feat/T-043-payment` → CI → squash merge; ROADMAP [x], PROGRESS, STATE bo'sh shablon.

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
