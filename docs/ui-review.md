# UI/UX tekshiruvi (T-091)

`prompts/03-ui-review.md` bo'yicha. Har ekran `docs/specs/design-system.md` tekshiruv ro'yxati bilan baholandi; asosiy vosita — golden'lar (3 o'lcham × 2 mavzu) va avtomatik testlar.

## Avtomatik tekshiruvlar (CI'da har PR)
| Tekshiruv | Qayerda | Natija |
|---|---|---|
| 3 o'lcham × yorug'/qorong'i golden | `apps/pos/test/goldens/*` (kassa, to'lov, qaytarish, smena, tovarlar, tovar kartasi, import, kirim, inventarizatsiya, mijozlar, hisobotlar, sozlamalar, PIN, ulash, obuna), `packages/ui/widgetbook/test/goldens` | ✅ |
| Rus va o'zbek (kirill) matni sig'adi — barcha bo'limlar, to'lov, qaytarish, yangi tovar, inventarizatsiya, yangi kirim, yangi mijoz; telefon va planshet | `apps/pos/test/ui_review/locale_fit_test.dart` (20 test, overflow — xato) | ✅ |
| Rus tilidagi asosiy ekranlar (kassa, to'lov, hisobotlar) | `apps/pos/test/goldens/ui_review_golden_test.dart` | ✅ |
| Matnlar faqat tarjimada | `apps/pos/test/l10n/translations_test.dart`, `apps/admin/src/i18n/messages.test.ts` | ✅ |
| Kontrast WCAG AA (≥ 4,5:1) | `packages/ui/test/pos_theme_test.dart` | ✅ |
| Klaviatura: Ctrl+1..6, F1–F12, Esc, Enter; **bo'lim almashgandan keyin ham** | `apps/pos/test/app/shell_test.dart`, `features/*_test.dart` | ✅ (tuzatildi, quyida) |
| Admin: har sahifa 390 px telefonda va rus tilida gorizontal surilmaydi | `apps/admin/e2e/ui-review.spec.ts` | ✅ |

## Ekranlar
| Ekran | Asosiy amal (harakat) | Bo'sh / yuklanish / xato | Izoh |
|---|---|---|---|
| Kassa | Skan → F12 → Enter (3) | Bo'sh savat, skaner xatosi signali, savdo to'xtagan banneri | Jami — eng katta matn ✅ |
| To'lov | Naqd: Enter; karta/nasiya: 1 bosish + Enter | Limit, mijoz yo'q xatolari | Planshetda tugma ko'rinmas edi — tuzatildi |
| Qaytarish (F8) | Chek raqami/skan → qatorlar → PIN → tasdiq | Topilmadi, qaytarilgan | — |
| Smena / X-Z | Ochish 2, yopish 3 | — | — |
| Tovarlar, karta, import | Skan → karta ochiladi | Bo'sh katalog, import xatolari | — |
| Kirim, inventarizatsiya | Skan → miqdor → Tasdiqlash | Bo'sh qoralama, savdo to'xtaganda sabab | — |
| Mijozlar, nasiya | Qidiruv → karta → To'lash | Mijoz yo'q, topilmadi | — |
| Hisobotlar | Ctrl+5 → davr tugmasi (1) | Savdo yo'q, oflayn belgisi, kassirga ruxsat yo'q | — |
| Sozlamalar, PIN, ulash | — | Noto'g'ri PIN kutish, tarmoq xatosi | — |
| Admin: kirish, bosh sahifa, mijozlar, usta, mijoz sahifasi, tariflar, to'lovlar, qurilmalar, audit | — | Skelet, xato + qayta urinish, bo'sh jadvallar | Desktop asosiy, telefonda jadvallar o'z kartasida suriladi |

## Topilgan muammolar
| Ekran | Muammo | Og'irlik | Yechim |
|---|---|---|---|
| Kassa (Windows) | Boshqa bo'limga o'tib (Ctrl+2…6) kassaga qaytganda **F12, F1… va Ctrl+raqam ishlamay qolardi** — fokus route darajasiga tushib qolgan | **Yuqori** | Kassa ekrani faol bo'lganda fokusni qaytarib oladi (`didChangeDependencies` + `TickerMode`); regressiya testi `shell_test.dart` |
| To'lov (planshet 1024×768) va boshqa baland oynalar | Butun oyna surilardi — **"Yakunlash" tugmasi ekrandan pastda** (sensorli planshetda asosiy amal ko'rinmas) | **Yuqori** | `PosDialog`: faqat mazmun suriladi, sarlavha va tugmalar joyida; telefondagi pastki panel ham shunday |
| Admin: mijozlar filtri | Yuklama ostida qidiruv va holat filtri bir-birini bekor qilardi | O'rta | T-084 da tuzatildi (kutilayotgan URL `ref` da) |
| Admin: tariflar (planshet) | Amal tugmalari sig'masdi | O'rta | T-083 da tuzatildi (≤ 1280 px — ikonka) |
| Hisobotlar (telefon) | Davr tugmalari 2 qatorga tushadi | Past | Qoldirildi — hammasi ko'rinadi va bosiladi |
| Hisobotlar | KPI kartalari balandligi har xil ("Oldin" qatori yo'q kartada) | Past | Qoldirildi |
| Admin: jadvallar (telefon) | Jadval karta ichida gorizontal suriladi | Past | Qoldirildi — admin desktop uchun (spec), sahifa o'zi surilmaydi |
| Admin: Sozlamalar | Bo'lim hali qurilmagan ("tayyorlanmoqda") | O'rta | ROADMAP'da alohida vazifa yo'q — QUESTIONS/keyingi reja |

Skrinshotlar: `docs/screenshots/ui-review/` (rus tilidagi asosiy ekranlar va tuzatilgan to'lov oynasi/tovar kartasi).
