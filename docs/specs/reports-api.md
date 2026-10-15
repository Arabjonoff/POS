# Hisobotlar API (T-019)

Mahsulot talablari: `reports.md`. Kassa hisobotlarni lokal ma'lumotdan hisoblaydi (oflayn); bu API — server ma'lumoti bo'yicha (admin/veb, tekshiruv) **bir xil formulalar** bilan. Huquq: ega va menejer (`auth-roles.md`); kassir — `403`. Faqat o'z tenanti.

## Davr
- Har endpoint `?date_from=YYYY-MM-DD&date_to=YYYY-MM-DD` oladi (ikkalasi ham kiradi, **do'kon vaqt zonasida**, `Tenant.timezone`). Berilmasa — bugun. `date_from > date_to` yoki 366 kundan uzun — `400`.
- Savdo `sold_at`, qaytarish `at` bo'yicha davrga tushadi (qaytarish o'z kunida hisoblanadi, savdo kunida emas).

## Formulalar (pul — tiyin, butun son; yaxlitlash half-up, `money.py`)
- **Tannarx (qator):** `line_total(cost_tiyin, qty_milli)`; qaytarish qatorida — savdo qatori tannarxi × qaytarilgan miqdor.
- **Tushum** = Σ `Sale.total_tiyin` − Σ `Refund.total_tiyin` (chek chegirmasidan keyingi summa).
- **Foyda** = tushum − Σ savdo tannarxi + Σ qaytarilgan tannarx. (Q-004: `data-model.md` dagi qator formulasi chek chegirmasi va qaytarishlarni hisobga olmasdi.)
- **Cheklar soni** — davrdagi savdolar soni (qaytarilganlar ham); **o'rtacha chek** = `mul_div_half_up(Σ Sale.total, 1, cheklar soni)` (0 chek → 0).
- **Solishtirish** — shu uzunlikdagi oldingi davr (bugun ↔ kecha, 7 kun ↔ oldingi 7 kun): `change_bp` = `mul_div_half_up(joriy − oldingi, 10 000, oldingi)` (bazis punkt, 1% = 100; oldingi 0 bo'lsa `null`).
- To'lov turlari — `SalePayment` summalari (`cash`/`card`/`debt`), qaytarishlar alohida (`cash`/`debt`).

## Endpointlar — `GET /api/v1/reports/...`
| Yo'l | Javob |
|---|---|
| `summary/` | `{period, revenue_tiyin, sales_total_tiyin, refunds_total_tiyin, sales_count, average_check_tiyin, profit_tiyin, payments_tiyin{cash,card,debt}, refunds_tiyin{cash,debt}, previous{revenue_tiyin, profit_tiyin, sales_count}, revenue_change_bp, profit_change_bp}` |
| `by-day/` | `[{date, revenue_tiyin, sales_count, profit_tiyin}]` — davrdagi har kun (savdo bo'lmasa ham, nollar bilan) |
| `by-hour/` | `[{hour 0..23, revenue_tiyin, sales_count}]` — 24 qator |
| `top-products/?order=revenue\|qty\|profit&direction=desc\|asc&limit=1..100` (standart: revenue, desc, 20) | `[{product, name, qty_milli, revenue_tiyin, profit_tiyin}]` — qator summalari (chek chegirmasigacha) minus qaytarilganlar; faqat davrda sotilgan tovarlar |
| `cashiers/` | `[{cashier, full_name, sales_count, sales_total_tiyin, refunds_count, refunds_total_tiyin}]` |
| `debts/?limit=` (standart 20) | `{total_debt_tiyin, debtors_count, top: [{customer, full_name, phone, balance_tiyin}]}` — davrsiz, joriy holat |
| `stock/` | `{stock_value_tiyin, low: [...], negative: [...]}` — davrsiz; qiymat = Σ musbat qoldiq × tannarx; `low` — `min_stock_milli > 0` va qoldiq undan kam (qoldiq qatori bo'lmasa ham 0 deb), `negative` — qoldiq < 0. Qator: `{product, name, qty_milli, min_stock_milli}` |
- Eksport (xlsx) — klientda (kassa va admin), server faqat JSON beradi.

## Kassa uchun — `GET /api/v1/sync/reports/?date_from&date_to` (T-070)
- Autentifikatsiya: qurilma tokeni (`Authorization: Device <token>`); xodim JWT'si yetmaydi. Kim ko'rishi (ega/menejer) kassada lokal rol bilan cheklanadi.
- Javob bitta obyektda: `{summary, by_day, by_hour, top_products (20), cashiers, debts (top 10), stock}` — yuqoridagi endpointlar bilan bir xil formulalar.
- Sanalar `YYYY-MM-DD` (do'kon kuni). Tenant bo'yicha cheklangan.
- Umumiy test vektorlari: `testdata/report_vectors.json` — server (`apps/reports/tests/test_shared_vectors.py`) va kassa (`apps/pos/test/data/local_reports_test.dart`) bir xil raqam beradi.
