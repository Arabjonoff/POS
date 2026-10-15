# Chidamlilik testlari (T-090)

Elektr va internet tez-tez o'chadigan do'kon uchun kassa sinovlari. Hammasi `apps/pos` testlarida, CI'da har PR'da ishlaydi:

```sh
cd apps/pos && flutter test test/resilience test/data/sync_engine_test.dart
```

| Ssenariy | Test | Natija |
|---|---|---|
| 500 savdo oflayn → internet qaytadi, birinchi paket javobi yo'qoladi | `test/resilience/offline_sales_test.dart` | Serverda **aniq 500** savdo (takror yo'q), qoldiq to'g'ri, navbat bo'sh. Yozish **3,7 ms/savdo** (fayl, WAL + `synchronous=FULL`), sinxron 136 ms (6 paket × 100, biri qayta) |
| 500 savdo oflayn → onlayn (sync.md 5) | `test/data/sync_engine_test.dart` | Serverda 500 |
| Push o'rtasida uzilish (sync.md 6) | `test/data/sync_engine_test.dart` | Qayta yuborishda takror yo'q |
| **Savdo tranzaksiyasi o'rtasida jarayon o'ladi** | `test/resilience/crash_test.dart` (+ `crash_child.dart` — alohida `dart` jarayoni, `exit` bilan o'ldiriladi) | COMMIT'gacha o'lsa — savdo, qatorlar, qoldiq harakati, outbox **hech biri yo'q**, `PRAGMA integrity_check = ok`, keyingi savdo odatdagidek; COMMIT'dan keyin o'lsa — savdo saqlangan |
| 2 kassa bir tovarni oflayn sotadi | `test/resilience/two_devices_test.dart` | Har kassa o'z sotuvini darhol ko'radi; sinxrondan keyin ikkalasi server qoldig'iga yaqinlashadi (10 − 1 − 2 = 7), ikki marta ayirilmaydi; javob yo'qolsa ham bir marta |
| 2 qurilma bir tovar (server) | `backend/apps/sync/tests` (T-018) | Server ikkala savdoni qabul qiladi, qoldiq = harakatlar yig'indisi |
| 10 000 tovar: katalog | `test/resilience/large_catalog_test.dart` | Bazadan yuklash **75 ms**, qidiruv **1,5 ms/harf** (chegara 50 ms) |
| 10 000 tovar: kassa ekrani ochilishi | `test/resilience/large_catalog_test.dart` | **~0,85 s** (test muhiti, chegara 10 s); oxirgi tovar skaner bilan topiladi |

O'lchovlar: Windows 11 ishchi kompyuter, `flutter test` (2026-10-15). Haqiqiy kassa qurilmasida (arzon Android planshet) sekinroq bo'lishi mumkin — T-093 da qurilmada qayta o'lchanadi.

## Nimaga tayanadi
- Lokal SQLite: `journal_mode=WAL`, `synchronous=FULL` (`app_database.dart`), hujjat + qoldiq + outbox **bitta tranzaksiyada** (`SaleWriter`).
- Outbox: UUIDv7 id, server `id` bo'yicha idempotent (`duplicate`), eksponensial kutish (`sync.md`).
- Qoldiq = server qoldig'i (pull) + hali tasdiqlanmagan lokal harakatlar (`stockQuery`).
