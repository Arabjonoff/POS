# STATE — hozirgi ish holati (nazorat nuqtasi)

> Bu fayl **har doim** hozirgi holatni ko'rsatadi. Agent har qadamdan keyin uni yangilaydi, commit va push qiladi.
> Elektr yoki internet o'chib, ish to'xtasa — keyingi sessiya **birinchi navbatda shu faylni** o'qiydi va shu yerdan davom etadi.
> Format qat'iy: bo'limlar nomini o'zgartirma.

## Joriy vazifa
- Vazifa: T-050 Tovarlar ro'yxati va kartasi
- Branch: feat/T-050-products
- Boshlangan: 2026-10-15
- Oxirgi yangilanish: 2026-10-15

## Qadamlar (vazifa ichida)
<!-- Agent vazifani boshlaganda shu ro'yxatni yozadi va har qadamda belgilaydi -->
- [ ] 1. Backend: `GET /api/v1/products/{id}/price-history/` (owner/manager; boshqa tenant — 404) + pytest + OpenAPI + `make api-clients`
- [ ] 2. Kassa: `data/catalog/product_editor.dart` — tekshiruv (nom, birlik, narx, shtrix-kod nazorat raqami va takrori, PLU 5 raqam va takrori, vaznli → kasrli birlik), saqlash (products + product_barcodes + outbox `product.upserted` bitta tranzaksiyada, `by` — menejer/ega), nofaol qilish; qoldiq (`product_stock` + yuborilmagan harakatlar) + testlar
- [ ] 3. Tovarlar ro'yxati (bo'lim "Tovarlar"): qidiruv, kategoriya, filtrlar (kam qolgan, manfiy, nofaol), desktop jadval / telefon kartalar, bo'sh holat; skaner → mavjud bo'lsa karta, yo'q bo'lsa yangi karta (shtrix-kod to'ldirilgan)
- [ ] 4. Tovar kartasi: maydonlar, shtrix-kodlar (skaner bilan qo'shish, takror ogohlantirish), ustama %, narx tarixi (onlayn), saqlash/nofaol qilish; kassir → menejer PIN; tarjimalar
- [ ] 5. Widget testlari + golden + skrinshotlar `docs/screenshots/T-050/`
- [ ] 6. Spec, PR, CI → merge; ROADMAP, PROGRESS, STATE

## Oxirgi bajarilgan ish
- T-046 merge qilindi (#30). T-047 → Q-007 (qurilma kerak). T-050 boshlandi.

## Keyingi aniq harakat
- 1-qadam: `backend/apps/catalog/views.py` ProductViewSet ga `@action(detail=True) price_history`, serializer, testlar `backend/apps/catalog/tests/`. Docker: `docker info` javob berguncha kut, keyin `make up` (portlar .env da: postgres 55432).

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
