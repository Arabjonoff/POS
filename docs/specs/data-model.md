# Ma'lumotlar modeli (MVP)

Umumiy maydonlar (barcha biznes jadvallarida): `id` UUIDv7 (klientda yaratiladi), `tenant_id`, `created_at`, `updated_at`.
Katalog jadvallarida qo'shimcha: `deleted_at` (yumshoq o'chirish).
Pul: `*_tiyin` (bigint). Miqdor: `qty_milli` (bigint; 1 dona = 1000, 0,250 kg = 250).

## SaaS qatlami (faqat serverda)
| Model | Maydonlar |
|---|---|
| Tenant | name, owner_phone (`+998XXXXXXXXX`), address, timezone (Asia/Tashkent), default_locale (uz/uz-Cyrl/ru), notes, is_blocked, blocked_reason. `status` (trial/active/grace/readonly/blocked) saqlanmaydi — Subscription va `is_blocked` dan hisoblanadi. Yangi tenantga bitta Store avtomatik yaratiladi |
| Plan | name, price_tiyin_per_month, max_devices, max_users, features (JSON), is_active, sort |
| Subscription | tenant (1:1), plan, trial_ends_at, paid_until, grace_days (default 3), offline_days (default 7) |
| SubscriptionPayment | tenant, amount_tiyin, months, paid_at, period_from, period_to, method (cash/transfer/card/other), note, recorded_by |
| Device | tenant, store, name, platform (windows/android/ios), app_version, last_sync_at, last_ip, is_blocked, token_hash |
| AdminAuditLog | actor, action, target_type, target_id, before (JSON), after (JSON), at |
| SyncEvent | id (klient event UUID), tenant, device, type, payload (JSON), client_created_at, received_at, status (applied/rejected), error |
| ChangeLog | seq (BigAutoField), tenant, entity, entity_id, op (upsert/delete) — pull uchun |

## Do'kon qatlami (server + kassa SQLite)
| Model | Maydonlar |
|---|---|
| Store | name, address, phone, receipt_header, receipt_footer |
| User | phone (unique), full_name, role (owner/manager/cashier), password (faqat owner/manager), pin_hash, is_active |
| Category | name, parent_id, sort, color |
| Unit | code (pcs/kg/g/l/m/pack), name, is_fractional |
| Product | name, category_id, unit_id, sell_price_tiyin, cost_price_tiyin, is_weighted, plu_code (vaznli tovar uchun 5 raqam), min_stock_milli, ikpu_code (ixtiyoriy), quick_button (bool), is_active |
| ProductBarcode | product_id, barcode (tenant ichida unique), is_primary |
| PriceHistory | product_id, sell_price_tiyin, cost_price_tiyin, changed_by, at |
| Customer | full_name, phone, note, debt_limit_tiyin (null = cheklovsiz) |
| Shift | store_id, device_id, opened_by, opened_at, opening_cash_tiyin, closed_by, closed_at, counted_cash_tiyin, expected_cash_tiyin |
| Sale | shift_id, device_id, cashier_id, customer_id?, number (qurilma ichida ketma-ket, `D3-000123`), subtotal_tiyin, discount_tiyin, total_tiyin, status (completed/partially_refunded/refunded), sold_at |
| SaleItem | sale_id, product_id, name_snapshot, barcode_snapshot, qty_milli, price_tiyin, cost_tiyin, discount_tiyin, total_tiyin |
| SalePayment | sale_id, method (cash/card/debt), amount_tiyin, received_tiyin (naqd uchun), change_tiyin |
| Refund | sale_id, cashier_id, approved_by, reason, total_tiyin, method (cash/debt), at |
| RefundItem | refund_id, sale_item_id, qty_milli, total_tiyin |
| CashMovement | shift_id, type (in/out), amount_tiyin, reason, by, at |
| Supplier | name, phone, note |
| StockReceipt | supplier_id?, number, status (draft/posted), total_cost_tiyin, note, posted_at, posted_by |
| StockReceiptItem | receipt_id, product_id, qty_milli, cost_price_tiyin, new_sell_price_tiyin? |
| InventoryCount | status (draft/posted), scope (all/category), category_id?, posted_at |
| InventoryCountItem | count_id, product_id, expected_milli, counted_milli |
| StockMovement | product_id, store_id, qty_milli (+/−), type (receipt/sale/refund/adjustment/inventory), ref_type, ref_id, at |
| DebtEntry | customer_id, amount_tiyin (+ qarz, − to'lov), type (sale/payment/refund/adjustment), sale_id?, note, by, at |
| OutboxEvent (faqat klient) | id, type, payload, created_at, attempts, last_error, sent_at |
| SyncState (faqat klient) | pull_cursor, last_push_at, last_pull_at, subscription_snapshot (JSON), offline_grace_until |

## Hisoblanadigan qiymatlar
- Qoldiq = `SUM(StockMovement.qty_milli)` (tovar + do'kon). Serverda `ProductStock` kesh jadvali bo'lishi mumkin, lekin manba — harakatlar.
- Mijoz qarzi = `SUM(DebtEntry.amount_tiyin)`.
- Foyda = tushum (savdolar − qaytarishlar) − Σ `line_total(cost_tiyin, qty_milli)` sotilgan + qaytarilgan tannarx (half-up; chek chegirmasi va qaytarishlar hisobga olinadi — Q-004, `reports-api.md`).
