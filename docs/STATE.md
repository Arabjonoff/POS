# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-043 To'lov oynasi
- Branch: feat/T-043-payment
- Boshlangan: 2026-10-14
- Oxirgi yangilanish: 2026-10-14

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [x] 1. To'lov modeli `apps/pos/lib/features/pos/payment/payment_draft.dart` (naqd/karta/nasiya/aralash, olingan, qaytim, qoldiq, `SalePaymentInput` lar) + unit testlar
- [x] 2. Mijozlar: `apps/pos/lib/data/customers/customer_directory.dart` (qidiruv, balans = Σ debt_entries, tez yaratish + `customer.upserted` outbox, limit tekshiruvi) + testlar
- [x] 3. `Checkout` (`features/pos/payment/checkout.dart`): savat + to'lov → `SaleWriter.complete` (bitta tranzaksiya) → savat tozalanadi; atomarlik testi
- [ ] 4. To'lov oynasi UI (`features/pos/payment/payment_dialog.dart`): Naqd (Aniq/50 000/100 000/200 000, klaviatura, katta yashil qaytim, Enter), Karta, Nasiya (mijoz tanlash/yaratish, limit → menejer PIN), Aralash; oyna ochiqda skaner → "Avval to'lovni yakunlang"
- [ ] 5. Kassa ekraniga ulash: F12, F4 mijoz (savatga), yakunlash xabari 3 s "Savdo yakunlandi · Qaytim …", fokus skanerga
- [ ] 6. Widget testlari (3 harakat: skan → F12 → Enter; qaytim; karta; nasiya + limit; aralash; skaner bloklangan) + golden + skrinshotlar `docs/screenshots/T-043/`
- [ ] 7. To'liq tekshiruv, PR, CI → merge; ROADMAP, PROGRESS, STATE

## Oxirgi bajarilgan ish
- 3-qadam: `features/pos/payment/checkout.dart` (`checkoutProvider`), `CartController.setCustomer`, test `test/features/checkout_test.dart` (atomarlik).

## Keyingi aniq harakat
- 4-qadam: `features/pos/payment/payment_dialog.dart` — `showPaymentDialog(context, cart)` → natija; tablar Naqd/Karta/Nasiya/Aralash, `ScanListener` (skan → "Avval to'lovni yakunlang"), mijoz tanlash `features/pos/payment/customer_picker.dart`; tarjimalar node skript bilan (scratchpad `addkeys.mjs`).

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
