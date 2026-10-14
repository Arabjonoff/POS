# Mijozlar va nasiya API (T-016)

Foydalanuvchi JWT'si bilan. Boshqa tenant obyekti — `404`. Pul — `*_tiyin`, faqat butun son (qoida 1). Mahsulot talablari: `debts.md`; modellar: `data-model.md`.

## Mijoz — `/api/v1/customers/`
- `{id?, full_name, phone, note, debt_limit_tiyin, balance_tiyin, created_at, updated_at}`.
- `full_name` majburiy. `phone` ixtiyoriy, unique emas, berilsa `+998XXXXXXXXX` formatida (`apps/core/phone.py`).
- `debt_limit_tiyin`: `null` — cheklovsiz, `0` — nasiya berilmaydi, `> 0` — chegara.
- `id` klientda yaratilishi mumkin (UUIDv7; kassa oflaynda mijoz yaratadi). Band bo'lsa — `400`.
- `balance_tiyin` — faqat o'qish, `SUM(DebtEntry.amount_tiyin)`; musbat — mijoz qarzdor.
- Ro'yxat: `?search=` (ism yoki telefon, qisman), `?has_debt=true` (balans > 0). Tartib: qarzdorlar birinchi, qarz kamayib boradi, keyin ism.
- O'chirish — yumshoq (`deleted_at`). Qarzi bor (balans ≠ 0) mijozni o'chirib bo'lmaydi — `409 customer_has_debt`.

## Qarz yozuvi (`DebtEntry`)
- **O'zgarmas** (`AppendOnlyModel`): tahrir yoki o'chirish yo'q, xato — teskari yozuv bilan tuzatiladi (qoida 3).
- `{id, customer, amount_tiyin (≠ 0; + qarz, − to'lov), type, method?, sale_id?, note, created_by, at}`.
- Turlar:
  - `sale` (+) — qarzga savdo. Faqat savdo bilan birga yaratiladi (T-017, sinxron orqali). `sale_id` majburiy.
  - `refund` (−) — qarzga sotilgan savdo qaytarildi (T-017). `sale_id` majburiy.
  - `payment` (−) — mijoz to'ladi. `method`: `cash` / `card`.
  - `adjustment` (±) — qo'lda tuzatish, faqat ega, `note` (sabab) majburiy.
- `GET /customers/{id}/debt-entries/` — mijoz tarixi, yangisi birinchi.

## Limit (qarzga sotish)
- `check_debt_limit(customer, amount)`: `debt_limit_tiyin` `null` bo'lsa — ruxsat; aks holda `balans + amount ≤ limit` bo'lsa ruxsat.
- Oshsa — kassada menejer PIN'i bilan ruxsat (`debts.md`). Serverga savdo sinxron orqali keladi va **rad etilmaydi** (savdo allaqachon bo'lgan, oflayn-birinchi): `approved_by` savdoda saqlanadi (T-017).

## To'lov — `POST /customers/{id}/payments/`
- `{id?, amount_tiyin > 0, method: cash|card, note?}` → `201` `{entry, balance_tiyin}`. Yozuv `amount_tiyin = −amount`.
- Mijoz qatori qulflanadi (bir vaqtda ikki to'lov balansni buzmasin).
- Joriy qarzdan ko'p to'lov — `409 payment_exceeds_debt` (`details: {balance_tiyin}`). Avans hozircha yo'q (Q-003).
- Huquq: tenantning istalgan xodimi (kassir to'lov qabul qiladi).

## Tuzatish — `POST /customers/{id}/adjustments/`
- `{id?, amount_tiyin ≠ 0, note (majburiy)}` → `201` `{entry, balance_tiyin}`. Faqat ega (`owner`).

## Huquqlar
| Amal | owner | manager | cashier |
|---|---|---|---|
| Mijozlarni ko'rish, tarix | ✓ | ✓ | ✓ |
| Mijoz yaratish, ism/telefon/izohni o'zgartirish | ✓ | ✓ | ✓ (kassada tez yaratish) |
| `debt_limit_tiyin` o'rnatish yoki o'zgartirish | ✓ | ✓ | — (`403`) |
| Mijozni o'chirish | ✓ | ✓ | — |
| To'lov qabul qilish | ✓ | ✓ | ✓ |
| Tuzatish (`adjustment`) | ✓ | — | — |

## Sinxron (T-018)
- `customer.upserted`, `debt.paid` hodisalari shu servislarni chaqiradi (`pay_debt(..., enforce_balance=False)` — oflaynda bo'lgan to'lov rad etilmaydi).
- Pull: Customer va DebtEntry.
