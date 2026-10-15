# Audit: customers, nasiya (debt), payments, refunds — and an "opening balance" design

Read-only audit of `main` @ 8a405ca. Backend tests: `apps/customers` passes (49 passed).
Specs read: CLAUDE.md, docs/specs/debts.md, customers-api.md, sync.md, sync-api.md, sales-api.md, QUESTIONS.md (Q-003).

---------------------------------------------------------------------------------------------------
## 1. How balances work today
---------------------------------------------------------------------------------------------------

### 1.1 Ledger model (server) — `backend/apps/customers/models.py`
- `DebtEntry(AppendOnlyModel, TenantScopedModel)` (models.py:55-117). `save()` only for new rows, `delete()` raises
  `ImmutableRecordError` (core/models.py:88-100). Corrections only by a reverse entry.
- Fields: `amount_tiyin` BigInteger (signed), `type`, `method` (cash|card, payment only), `sale_id` (UUID, no FK on
  purpose — sale may sync later), `shift` FK (nullable), `note`, `created_by`, `at` (default now, client-supplied
  for sync events).
- Sign convention: **+ = customer owes more, − = owes less**. Positive balance = customer is a debtor.
- Types and DB CHECK constraints (models.py:96-114):
  | type | sign | method | sale_id | created by |
  |---|---|---|---|---|
  | `sale` | > 0 | "" | required | `record_sale_debt` (from `sale.completed`) |
  | `refund` | < 0 | "" | required | `record_refund_debt` (from `refund.created`, method=debt) |
  | `payment` | < 0 | cash/card | null | `pay_debt` (REST `/payments/`, sync `debt.paid`) |
  | `adjustment` | ± (≠0) | "" | null | `adjust_debt` (REST `/adjustments/`, owner only; no sync event, no UI anywhere) |
  Plus `debt_amount_not_zero`.

### 1.2 Balance: derived, not cached
- Server: `customer_balance()` = `SUM(DebtEntry.amount_tiyin)` (services.py:13-15); list/detail annotate via
  `with_balance()` (services.py:18-20). `Customer` has no balance column. Never edited directly.
- Kassa (Drift): `customers.balance_tiyin` column holds the server value from the last *customer* pull; the real
  balance is `SUM(debt_entries)` (pulled entries + entries written locally, same table, same ids → upsert).
  `CustomerDirectory._all()` (customer_directory.dart:118-140): if the customer has ≥1 local entry → ledger sum,
  else → stale server `balance_tiyin` fallback.
- Pull: `customer` (with annotated balance) and `debt_entry` entities (sync/pull.py:47,50). Note: creating a
  DebtEntry does NOT log a ChangeLog row for the Customer, so the pulled `balance_tiyin` goes stale; the ledger
  path is what keeps the kassa correct.

### 1.3 Negative balance / advance
- DB allows it (no constraint on the sum; `adjustment` ±; `refund` −).
- Policy (Q-003, still unanswered, temporary choice A): **no advance** — REST `pay_debt` rejects
  `amount > balance` with `409 payment_exceeds_debt` (services.py:99-108); kassa `payDebt` rejects the same way
  locally (customer_directory.dart:287-288). With a negative balance *every* payment is rejected.
- But negative balances already happen de facto:
  1. sync `debt.paid` uses `enforce_balance=False` (two kassas both take the full payment offline → −X);
     tested in `test_offline_payment_not_rejected`;
  2. refund with method=debt is capped only by the *sale's* debt part (`_debt_left`, refunds.py:88-91,116),
     not by the customer's current balance → if the customer already paid, the refund makes the balance negative;
  3. owner adjustment.
  The UI has no wording for it: card shows "Qarz: −50 000 so'm" (customer_card.dart:111-118); list shows
  "Qarzi yo'q" (customers_screen.dart:125-135); customer picker "Qarzi: −50 000".
- A later debt sale consumes a negative balance naturally (sum), and `allowsDebt`/`check_debt_limit`
  (`balance + amount <= limit`) work with negatives. There is no "pay the advance back in cash" flow.

### 1.4 Debt limit
- `Customer.debt_limit_tiyin`: null = unlimited, 0 = no credit, >0 = cap (CHECK ≥ 0).
- Only owner/manager may set/change it: REST `validate_debt_limit_tiyin` (serializers.py:35-40) → 403 for cashier;
  sync `customer.upserted` uses the same serializer with `by` as the user; kassa asks manager PIN and sends the
  approver as `by` (customer_card.dart:434-445). Kassa sends `debt_limit_tiyin` only when changed.
- Enforcement: kassa payment dialog `allowsDebt` (payment_dialog.dart:217,480) → manager PIN. Server never rejects
  a synced debt sale over limit (offline-first); `approved_by` stored on the Sale.

### 1.5 Payments
- REST `POST /customers/{id}/payments/` `{id?, amount_tiyin ≥1 (StrictInteger), method cash|card, note}` → locks
  customer row (`select_for_update`), checks balance, writes `DebtEntry(−amount, payment)`. Any tenant member.
- Kassa `CustomerDirectory.payDebt` (customer_directory.dart:276-322): one Drift transaction → local
  `DebtEntry(−amount, payment, method, shiftId?)` + outbox `debt.paid {id, customer, amount_tiyin, method, note,
  shift?, at, by}`. Server handler `debt_paid` (sync/handlers.py:59-80) → `pay_debt(enforce_balance=False)`, same id.
- Cash payment with `shift` → counted in expected cash (server shifts.py:46-53, kassa shift_service.dart:305-323)
  and in X/Z `debt_payments_tiyin`. Never counted as sale revenue.

### 1.6 Refunds of credit sales
- Kassa `refund_writer.dart:44-46,114-153`: method=debt allowed only if `debtLeftTiyin > 0 && total ≤ debtLeft`
  (refund_calculator.dart:162-163); writes local `DebtEntry(−total, refund, sale_id)` + `debt_entry_id` in payload.
- Server `record_refund` (sales/services/refunds.py:94-170): re-validates items/totals, debt cap per sale
  (line 116), `record_refund_debt(..., id=debt_entry_id, shift)`.

### 1.7 Server recompute / validation
- `sale.completed` (sales/services/sales.py): recomputes line totals, subtotal/discount/total, payments sum,
  `debt` needs customer, writes `DebtEntry(+Σdebt, sale)` with the client `debt_entry_id`.
- All money via `StrictIntegerField` / `as_int` (rejects floats, strings, bools).

### 1.8 Sync idempotency
- Event level: `SyncEvent.pk` = client outbox event UUID; re-push of same id → `duplicate`, handler not re-run
  (sync/services.py:216-224). Other device using same id → `id_conflict`.
- Entity level: DebtEntry PK = client UUIDv7 (`id`, `debt_entry_id`); Sale/Refund have explicit "already exists"
  checks. A *different* event carrying an already-used DebtEntry id → IntegrityError → caught by the generic
  `except Exception` → `pending` "server_error", retried for 7 days, then rejected (not a clean reject).
- Ordering: push sorts by `created_at`; `MissingDependency` → `pending` and retried after each applied batch
  (`debt.paid` for unknown customer → pending; but see bug B2 for `sale.completed`).
- Tenant: handlers always filter by `device.tenant_id`; `ClientIdMixin` rejects ids that exist globally.

---------------------------------------------------------------------------------------------------
## 2. Design: opening balance ("Boshlang'ich balans")
---------------------------------------------------------------------------------------------------

### 2.1 Decisions
- New DebtEntry type **`opening`**, signed: `+` = customer owes the shop (debt), `−` = shop owes the customer
  (prepaid / avans). `method=""`, `sale_id=NULL`, `shift=NULL` (never in a shift → never in expected cash).
- **At most one `opening` entry per customer** (DB partial unique index) → editing can never double-add.
- Created **only on customer creation**, in the same local transaction as the customer row and its outbox event.
- `at` = user-chosen opening date (optional; default = now). Must be ≤ now (+5 min skew) and ≥ 2000-01-01.
- Credit (avans) is new business semantics vs Q-003 ("avans yo'q") → record in QUESTIONS.md / a decision
  (`docs/decisions/0010-opening-balance.md`). The ledger already tolerates negative sums, so no structural change.
- Permissions (fraud): a fake **credit** lets someone take goods for free via "Nasiya" sales → credit opening
  needs owner/manager (kassa: manager PIN, `by` = approver; server: role check). Debt opening may be entered by any
  staff (a fake debt gives nobody goods or cash). Put the cashier/debt choice to the owner as a question.

### 2.2 Transport — embed in `customer.upserted` (recommended)
Payload on creation only:
```
customer.upserted {id, full_name, phone, note, by,
  opening_balance?: {id: uuid7, direction: "debt"|"credit", amount_tiyin: int > 0, at: iso, note?: str}}
```
Why embedded rather than a separate `debt.opened` event: atomic on the server too (customer + entry in the one
handler savepoint), no ordering/pending issues, and the "edit" path physically can't create an opening.
Explicit `direction` + positive amount avoids sign mistakes in clients.
(Alternative if preferred: separate `debt.opened {id, customer, direction, amount_tiyin, at, by, note}` handler
raising `MissingDependency` when the customer is missing; same constraints.)

Backwards compatibility: server deployed first; old kassas never send `opening_balance` → unchanged behaviour.
Old kassas pulling a `debt_entry` with `type: "opening"`: POS parses raw JSON (no generated enum), balance sums
correctly, history label falls back to `debtAdjustment` (customer_card.dart:41-46) — acceptable. Admin TS client
gets `DebtEntryTypeEnum` + "opening" after `make api-clients` (admin has no customers UI yet).

### 2.3 Server changes
1. `models.py`: `DebtType.OPENING = "opening", _("boshlang'ich balans")`; constraints:
   - `debt_sign_matches_type`: add `| Q(type="opening")` (non-zero already enforced);
   - `debt_sale_id_for_sale_and_refund`: second branch `Q(type__in=["payment","adjustment","opening"])`;
   - new `debt_opening_no_sale_no_shift`: `~Q(type="opening") | Q(sale_id__isnull=True, shift__isnull=True)`;
   - new `UniqueConstraint(fields=["customer"], condition=Q(type="opening"), name="debt_one_opening_per_customer")`.
2. Migration `customers/0003_debtentry_opening.py`: AlterField(type choices), RemoveConstraint/AddConstraint for the
   two widened checks, AddConstraint ×2. Only widens what is allowed; all existing rows satisfy the new checks.
3. `services.py`:
   ```python
   @transaction.atomic
   def record_opening_balance(customer, *, direction, amount_tiyin, user, at=None, note="", id=None):
       _positive(amount_tiyin)
       customer = _lock(customer)
       if DebtEntry.objects.filter(customer=customer, type=DebtType.OPENING).exists():
           raise DomainError("opening_balance_exists", "Opening balance is already set.", 409)
       sign = 1 if direction == "debt" else -1
       return _create(customer, **({"id": id} if id else {}), amount_tiyin=sign * amount_tiyin,
                      type=DebtType.OPENING, note=note, created_by=user, at=at)
   ```
4. `serializers.py`: `OpeningBalanceSerializer(id UUID?, direction ChoiceField, amount_tiyin StrictInteger(min 1),
   at DateTime?, note Char(blank, max 500))` with `validate_at` (not future, ≥ 2000), `validate_id` (global unique).
   `CustomerSerializer.opening_balance = OpeningBalanceSerializer(write_only=True, required=False, allow_null=True)`.
   - `validate_opening_balance`: `self.instance is not None` → `ValidationError(code="opening_create_only")`
     (or ignore if an opening entry with the same id already exists); `direction == "credit"` and role CASHIER →
     `PermissionDenied`.
   - `create()` inside `transaction.atomic`: pop `opening_balance`, `super().create()`, then
     `record_opening_balance(customer, user=request.user, **opening)`. Works for REST (`perform_create`) and sync
     (`_upsert` → `serializer.save(id, tenant_id)`; handler already in a savepoint).
   - Also normalize phone here (see bug B1).
5. `pay_debt` unchanged: with credit balance any payment is still 409 (no top-up) until Q-003 is answered.
6. Reports:
   - Sales/revenue/profit (reports/services.py `_totals`, `summary`, `by_day`…) read Sale/SalePayment/Refund only →
     opening is excluded automatically. Add a test that proves it.
   - Shift expected cash / X-Z (sales/services/shifts.py:42-53,106-121) filter `type=payment` + `shift` → excluded.
     Kassa `shift_service.dart:305-309` same → excluded.
   - Debts report (reports/services.py:288-300) sums all entries → a debt opening is counted in `total_debt_tiyin`
     (correct: real receivable). Credit customers (balance < 0) are filtered out → add additive fields
     `total_credit_tiyin` and `creditors_count` (OpenAPI additive, admin-compatible).
7. Docs: customers-api.md (type table, payload, permissions row "Boshlang'ich avans" owner/manager),
   sync-api.md (customer.upserted payload), debts.md (UI), data-model.md, decision file, QUESTIONS.md entry.

### 2.4 Kassa (Flutter) changes
- No Drift schema change (`debt_entries.type` is free text; `at` exists).
- `CustomerDirectory.create({..., OpeningBalanceInput? opening})` where
  `OpeningBalanceInput {OpeningDirection direction /*debt|credit*/, int amountTiyin /*>0*/, DateTime at, String? approvedBy}`.
  In the existing `_db.transaction`: insert customer → if `opening != null`: insert
  `DebtEntriesCompanion(id: openingId, customerId, amountTiyin: ±amount, type: 'opening', at: opening.at,
  byUserId: approvedBy ?? createdBy, shiftId: null)` → enqueue `customer.upserted` with `opening_balance` map
  (`at: isoUtc(opening.at)`), `by` = approver for credit. Return `CustomerEntry(balanceTiyin: ±amount)`.
  Amount 0 / no opening → exactly today's code path (no entry, no field).
- `CustomerDirectory.update(...)` untouched — it never writes debt entries, never sends `opening_balance`.
- UI `_NewCustomerDialog` (customers_screen.dart:233-302) — new section "Boshlang'ich balans":
  - segmented choice (3 options): "Yo'q" (default) / "Mijoz qarzi" / "Mijoz haqi (avans)";
  - when not "Yo'q": `MoneyInput` (required > 0) + date field (default today, max today);
  - helper text under the choice: "Mijoz do'konga qarzdor" / "Do'kon mijozga qarzdor (oldindan to'lagan)";
  - "Mijoz haqi (avans)" by a cashier → `requestManagerApproval` before save (same as limit edit);
  - dialog returns a record object instead of `(String, String)`.
  - packages/ui has no segmented control or date field: add `PosSegmentedControl` and `PosDateField`
    (Material `showDatePicker` themed with tokens) to `packages/ui` + Widgetbook + goldens (rule 7).
  - Quick-create in the payment dialog (customer_picker.dart) stays name+phone only (3-step sale rule).
- Customer card (customer_card.dart):
  - `_type`: `'opening' => amount > 0 ? l10n.debtOpeningDebt : l10n.debtOpeningCredit`
    ("Boshlang'ich qarz" / "Boshlang'ich avans"); show date only (no time) for opening rows.
  - Header: balance > 0 → "Qarz" (danger); < 0 → "Mijoz haqi (avans)" with `abs()` (success tone); 0 → "Qarzi yo'q".
  - List (customers_screen.dart:125-135) and picker (customer_picker.dart:180-183): show "Avans: 50 000 so'm"
    for negative balance instead of "Qarzi yo'q"/"Qarzi: −50 000".
  - "Qarzni to'lash" button stays hidden for balance ≤ 0.
- l10n keys in app_uz.arb, app_uz_Cyrl.arb, app_ru.arb: `customerOpeningSection`, `customerOpeningNone`,
  `customerOpeningDebt`, `customerOpeningCredit`, `customerOpeningDebtHint`, `customerOpeningCreditHint`,
  `customerOpeningDate`, `customerOpeningNeedsApproval`, `debtOpeningDebt`, `debtOpeningCredit`, `customerCredit`,
  `payCustomerCredit`.
- Payment dialog: when a credit customer pays with "Nasiya", label could read "Avansdan" — optional polish.

### 2.5 Consistency walk-through (credit 50 000 → sale 30 000 on nasiya → refund 10 000 debt → payment)
opening −50 000 → sale +30 000 → balance −20 000 → refund −10 000 → −30 000 → payment rejected (balance ≤ 0).
Debt opening 100 000 → payment 40 000 (cash, shift) → 60 000; expected cash +40 000; revenue unchanged.
Edit name/phone → `customer.upserted` without `opening_balance`; server serializer refuses opening on update; DB
unique index is the last guard.

### 2.6 Tests to add
Backend (apps/customers/tests/test_opening.py, apps/sync/tests/test_push.py, apps/reports/tests):
- create with debt opening → balance +X, one `opening` entry, `at` = given, `shift` null;
- credit opening by manager → −X; by cashier → 403 (REST) / `permission_denied` (sync);
- no / null opening → zero entries (regression of "works as before");
- PATCH with `opening_balance` → 400, entry count unchanged; PATCH name → balance unchanged;
- second opening via service → 409; DB unique constraint → IntegrityError; sign/sale_id/shift constraints;
- invalid: amount 0, −1, 1.5, "100", direction "x", future `at` → 400;
- sync: `customer.upserted` with opening applied; same event re-pushed → `duplicate`, still one entry;
  followed by `sale.completed` (debt) and `debt.paid` → balance correct;
- reports: summary revenue/payments and shift expected cash unchanged by opening; debts report counts debt opening,
  `total_credit_tiyin` counts credit;
- pull: `debt_entry` with `type: "opening"` serialized;
- tenant: opening entry `tenant_id` = customer tenant; other tenant's `/debt-entries/` 404; sync
  `customer.upserted` reusing a foreign customer id → rejected and foreign customer untouched.
Flutter: `customer_directory_test.dart` (entry + outbox payload in one transaction; amount 0 → no entry; update
never adds entries; balance sign); widget tests for the dialog (validation, approval for credit, date max today);
card labels; goldens/screenshots 390×844, 1024×768, 1440×900 in `docs/screenshots/T-XXX/`.

---------------------------------------------------------------------------------------------------
## 3. Bugs found
---------------------------------------------------------------------------------------------------

### B1 — HIGH: kassa sends un-normalized phone → server rejects the customer → debt sales of that customer are lost on the server
- Where: kassa `customer_directory.dart:184,195` (create) and `:344,359` (update) send `phone.trim()` as typed;
  UI `customers_screen.dart:257`, `customer_picker.dart:57`, `customer_card.dart:450` have no normalization or
  validation. Server `Customer.phone` validator accepts only `^\+998\d{9}$` (models.py:21-23, core/phone.py:33-36);
  `CustomerSerializer` does not call the existing `normalize_phone`.
- Verified: `CustomerSerializer(data={"full_name":"A","phone":"90 123 45 67"})` and `"901234567"` → invalid;
  only `+998901234567` or `""` pass (test_customers.py:39-40 asserts the 400).
- Impact: a cashier typing `90 123 45 67` creates the customer locally; `customer.upserted` is REJECTED; every
  later `sale.completed` with that customer is REJECTED ("Unknown customer", see B2) — sale, stock movement and
  debt missing on server; `debt.paid` sits `pending` 7 days then rejected. An edit with such a phone is rejected
  entirely (name/note too) while the kassa keeps the new values → permanent divergence. Name > 200 chars has the
  same effect (no maxLength in the kassa field).
- Fix: server — `CustomerSerializer.validate_phone`: `return normalize_phone(value) if value else ""` (raise
  ValidationError on ValueError); kassa — normalize/validate in the dialogs with an inline error
  (`l10n.phoneInvalid`), add a Dart `normalizePhone` mirroring core/phone.py, `maxLength: 200` on name.
- Tests: serializer accepts `90 123 45 67` → stored `+998901234567`; sync push of `customer.upserted` with spaced
  phone → applied; Flutter dialog shows error for `12345`.

### B2 — HIGH: `sale.completed` with a not-yet-applied customer is REJECTED instead of PENDING
- Where: backend/apps/sales/services/sales.py:84-88 — `raise invalid(CODE, "Unknown customer.")`.
  Contrast `debt_paid` (sync/handlers.py:62-64) which raises `MissingDependency`.
- Impact: if `customer.upserted` failed transiently (server_error → pending) or arrives later (split batches,
  device clock skew in `created_at` ordering), the debt sale is permanently rejected → revenue, stock and debt
  missing on server while the kassa shows them.
- Fix: `raise MissingDependency("customer", customer_id)` (pending, retried; rejected after 7-day TTL).
  Same review for `record_refund` (sale lookup already uses MissingDependency).
- Test: push `sale.completed` with debt for an unknown customer → `pending`; then push `customer.upserted` →
  both `applied`.

### B3 — MEDIUM: pending `debt.paid` becomes REJECTED once its shift is closed
- Where: sync/handlers.py:68,77 → `device_shift(device, shift_id)` with default `must_be_open=True`
  (sales/services/common.py:75-76).
- Impact: payment pending (customer missing, B1/B2 chain or transient error) → shift closes → retry raises
  `shift_closed` → payment lost on server; Z report expected cash already excluded it.
- Fix: `device_shift(device, shift_id, must_be_open=False)` for `debt.paid` (the payment happened during the
  shift; the closed shift's expected_cash should then be recomputed or the gap reported), or keep the entry with
  `shift=None` + note. Test: pending payment applied after shift close → applied.

### B4 — MEDIUM: debt payment accepted with no open shift → cash outside any shift
- Where: customer_card.dart:253 passes `currentShiftProvider.value?.id` (may be null); `payDebt` accepts
  `shiftId: null` (customer_directory.dart:281).
- Impact: cash received is not in any expected-cash / Z report → drawer looks over by that amount, money
  untraceable.
- Fix: for `method == 'cash'` require an open shift (disable button + message "Avval smenani oching"), or block
  both methods. Test: widget test with no shift.

### B5 — MEDIUM: negative balance (already reachable) is shown wrongly
- Where: customer_card.dart:111-118 ("Qarz" + negative number), customers_screen.dart:125-135 ("Qarzi yo'q"),
  customer_picker.dart:181 ("Qarzi: −…"). Causes of negative: offline double payment, debt refund after the debt
  was paid (refunds.py:116 caps only by the sale's debt part), adjustment.
- Impact: shop owes the customer money but staff see "no debt"; owner's debts report ignores it
  (reports/services.py:288-300 `balance > 0` only).
- Fix: part of 2.4 (avans labels) + report `total_credit_tiyin`. Decide in Q-003 whether a debt refund after full
  payment should be forced to cash.

### B6 — LOW: double `Navigator.pop` in new-customer dialog
- Where: customers_screen.dart:252-258 + `onSubmitted` (283): Enter then a fast click on "Saqlash" calls `_save`
  twice → second `pop` closes the underlying route (dialog still mounted during exit animation).
- Fix: `bool _done` guard. Test: tap Save twice → one customer, screen still shown.

### B7 — LOW: stuck "busy" state on unexpected errors
- customer_card.dart:233-273 (`_DebtPaymentDialog._submit`) catches only `PaymentExceedsDebtException`;
  customer_card.dart:446-460 (`_CustomerEditDialog._save`) has no try/finally; customers_screen.dart:48-50 no
  catch. A DB error leaves the spinner forever / unhandled future. Fix: try/finally + error toast.

### B8 — LOW: stale server balance fallback
- customer_directory.dart:136-138: with 0 local entries the stale `customers.balance_tiyin` (not refreshed when
  DebtEntries change on the server — no ChangeLog for Customer) is shown. Normally all entries are pulled so this is
  rare; safer: always use the ledger and drop the fallback, or have the server log the customer on each DebtEntry.

### B9 — LOW: REST payment retry is not idempotent
- serializers.py:62-65 (`_EntryInputSerializer.validate_id`): retrying the same `id` → 400 instead of returning
  the existing entry. Only REST/admin path; kassa uses sync (idempotent by event id). Fix: if an entry with that id
  exists for the same customer/type/amount → return 200 with it.
- Related: sync event with a reused DebtEntry id (other event id) → IntegrityError → generic "server_error"
  pending for 7 days (sync/services.py:175-179) instead of an immediate reject. Fix: catch IntegrityError →
  rejected `duplicate_id`.

### B10 — LOW: server search
- services.py:154-158: `phone__icontains=term` — "90 111 22" doesn't match "+998901112233"; name search not
  Latin/Cyrillic-insensitive (kassa handles both client-side). Fix: strip non-digits for phone when term has ≥3
  digits. Admin has no customers UI yet, so impact is low.

### Checked and OK
- Name blank / whitespace: rejected (DRF trims; test_customers.py:41); kassa dialogs require it.
- Phone uniqueness: intentionally NOT unique (spec) — test exists. Suggest a soft "this phone is already used by X"
  hint in the kassa (data quality), not a constraint.
- Negative / zero / float / string amounts: rejected for payments and adjustments (StrictIntegerField, tests).
- Payment > debt: 409 REST, local exception on kassa; sync accepts (by design).
- Double-submit of payment: `_busy` guard + server lock; edit dialog sets `_busy` synchronously before await.
- Permissions: cashier can create/edit name/phone/note and take payments; limit → manager/owner (403 / approval);
  delete → manager/owner; adjustment → owner. Matches the spec table.
- Tenant isolation REST: `test_other_tenant_isolated` covers list/retrieve/patch/delete/history/payments/
  adjustments. Sync: handlers filter by `device.tenant_id`; `ClientIdMixin` rejects foreign ids.
  **Missing tests**: sync `customer.upserted` with another tenant's customer id (must be rejected and untouched),
  `debt.paid` for a foreign customer, `sale.completed` referencing a foreign customer, and pull not leaking foreign
  `debt_entry` rows.
- Soft delete: balance ≠ 0 → 409; pull sends `delete` op (op_for) → kassa sets `deletedAt`.
