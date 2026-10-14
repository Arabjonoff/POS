# Savdo, smena, qaytarish, kassa puli (T-017)

Savdo kassada (oflayn) bo'ladi va serverga **faqat sinxron** (`sync.md`, T-018) orqali keladi. Server tomonida bu vazifa: modellar, hodisalarni qo'llovchi servislar (`apps/sales/services/`) va **faqat o'qish** uchun REST. Mahsulot talablari: `shifts.md`, `pos-screen.md`; modellar: `data-model.md`.

Umumiy qoidalar:
- ID'lar klientda yaratiladi (UUIDv7). Pul — `*_tiyin`, miqdor — `*_milli`, faqat butun son; yaxlitlash — `apps/core/money.py` (half-up).
- Savdo, savdo qatori, to'lov, qaytarish, pul harakati — **o'zgarmas** (qoida 3). `Sale.status` — yagona istisno: qaytarishda servis yangilaydi.
- Barcha bog'liq obyektlar (smena, kassir, tovar, mijoz, savdo) hodisa kelgan qurilmaning tenantiga tegishli bo'lishi shart; aks holda hodisa rad etiladi.
- Bog'liq obyekt hali yo'q bo'lsa (masalan, smena) — `MissingDependency` (sinxron uni `pending` qiladi). Qolgan xatolar — `DomainError(code)` (sinxron uni `rejected` qiladi).
- Biznes cheklovlari **savdoni rad etmaydi**: manfiy qoldiq, qarz limitidan oshish (kassada menejer ruxsati, `approved_by` saqlanadi).

## Smena
- `Shift {id, store, device, opened_by, opened_at, opening_cash_tiyin ≥ 0, closed_by?, closed_at?, counted_cash_tiyin?, expected_cash_tiyin?}`. Qurilmada bir vaqtda bitta ochiq smena (DB constraint).
- `shift.opened` → `open_shift(device, {id, cashier, opening_cash_tiyin, opened_at})`. Qurilmada ochiq smena bor — `shift_already_open`.
- `shift.closed` → `close_shift(device, {id, closed_by, counted_cash_tiyin, closed_at})`. `expected_cash_tiyin` serverda hisoblanadi va saqlanadi. Yopilgan smena — `shift_closed`.
- **Kutilayotgan naqd** = boshlang'ich naqd + naqd savdo to'lovlari − naqd qaytarishlar + kiritilgan − chiqarilgan + naqd qarz to'lovlari (`DebtEntry.shift` = shu smena).
- X/Z hisobot (`shift_report`): savdolar soni va jami, to'lov turlari bo'yicha (`cash`/`card`/`debt`), qaytarishlar soni va turlar bo'yicha, kiritilgan/chiqarilgan, qarz to'lovlari (naqd/karta), kutilayotgan naqd; yopilgan bo'lsa sanalgan naqd va farq (`counted − expected`).

## Kassa puli
- `cash.moved` → `record_cash_movement(device, {id, shift, type: in|out, amount_tiyin > 0, reason, by, at})`. Smena ochiq va shu qurilmaniki bo'lishi shart.

## Savdo
- `sale.completed` → `record_sale(device, payload)`:
```
{id, shift, number ("D3-000123"), cashier, customer?, approved_by?, sold_at,
 subtotal_tiyin, discount_tiyin, total_tiyin, debt_entry_id?,
 items: [{id, product, name_snapshot, barcode_snapshot, qty_milli, price_tiyin, cost_tiyin, discount_tiyin, total_tiyin}],
 payments: [{id, method: cash|card|debt, amount_tiyin, received_tiyin?, change_tiyin}]}
```
- Tekshiruvlar (`invalid_sale` + `details`):
  - kamida bitta qator; `qty_milli > 0`; narx, tannarx, chegirma ≥ 0;
  - qator: `total = line_total(price, qty) − discount ≥ 0`;
  - `subtotal = Σ qator total`; `0 ≤ discount ≤ subtotal`; `total = subtotal − discount`;
  - `Σ to'lov = total`, har to'lov `> 0`; naqd: `received ≥ amount`, `change = received − amount`; karta/nasiya: `received` yo'q, `change = 0`;
  - `debt` to'lovi bo'lsa `customer` majburiy.
- Smena shu qurilmaniki va ochiq bo'lishi shart (`shift_closed`). `number` tenant ichida yagona (`duplicate_number`).
- Bitta tranzaksiyada: Sale + SaleItem + SalePayment + har qatorga `StockMovement(sale, −qty)` + nasiya bo'lsa `DebtEntry(sale, +Σ debt)` (`record_sale_debt`).

## Qaytarish
- `refund.created` → `record_refund(device, payload)`:
```
{id, sale, shift, cashier, approved_by?, reason, method: cash|debt, total_tiyin, at, debt_entry_id?,
 items: [{id, sale_item, qty_milli, total_tiyin}]}
```
- Tekshiruvlar (`invalid_refund`):
  - qator shu savdoniki; `qty_milli > 0` va `≤ sotilgan − oldin qaytarilgan`;
  - qator summasi `= mul_div_half_up(sale_item.total, qty, sale_item.qty)`;
  - `total = Σ qator − chek chegirmasidan ulush` (`mul_div_half_up(sale.discount, Σ qator, sale.subtotal)`); qaytarish savdoni **to'liq** yopsa — `total = sale.total − oldingi qaytarishlar` (yaxlitlash qoldig'i qolmasin);
  - `method=debt` faqat savdoda nasiya to'lovi bo'lsa va `total ≤ nasiya summasi − oldingi nasiya qaytarishlari`.
- Smena shu qurilmaniki va ochiq. Bitta tranzaksiyada: Refund + RefundItem + har qatorga `StockMovement(refund, +qty)` + `method=debt` bo'lsa `DebtEntry(refund, −total)`; `Sale.status` → `partially_refunded` / `refunded`.
- Qaytarishga ruxsat (menejer PIN) kassada; `approved_by` berilsa — tenantning ega/menejeri bo'lishi shart.

## REST (faqat o'qish, JWT)
- `GET /api/v1/shifts/` (`?device=`, `?open=true`), `/shifts/{id}/`, `/shifts/{id}/report/`.
- `GET /api/v1/sales/` (`?shift=`, `?customer=`, `?date_from=`, `?date_to=` — `sold_at` sanasi, tenant vaqt zonasida), `/sales/{id}/` (qatorlar va to'lovlar bilan).
- `GET /api/v1/refunds/` (`?sale=`, `?shift=`), `/refunds/{id}/`.
- `GET /api/v1/cash-movements/` (`?shift=`).
- Huquq: tenantning istalgan xodimi; **kassir faqat o'zinikini** ko'radi (o'zi ochgan smenalar, o'z savdolari, qaytarishlari va pul harakatlari). Boshqa tenant — `404`. Yozish (POST/PATCH/DELETE) — `405`.
