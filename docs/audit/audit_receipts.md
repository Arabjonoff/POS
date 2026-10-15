# Audit: stock receipts (kirim), stock movements, inventory counts, stock levels

Repo: `C:\Users\Muhammadi\Downloads\POS-repo` @ `8a405ca` (main). The audit was read-only.
Backend tests `apps/inventory` and `apps/sync` all pass (run against a separate test DB, `pos_auditrc`, because another process was holding `test_pos`).
I confirmed four bugs with probe tests in the scratchpad (`scratchpad/probe/test_probe_receipts.py`). All four probes reproduced the bug.

---

## 1. How receipts work today

### 1.1 Data model

**Server** (`backend/apps/inventory/models.py`)

| Model | Fields | Notes |
|---|---|---|
| `Supplier` | name, phone, note, deleted_at (soft delete) | No balance, debt or payments. |
| `StockReceipt` | store, supplier?, number (per tenant, set by the server, tenant row locked), status `draft`/`posted`, total_cost_tiyin, note, **`reverses`** (OneToOne → self, related_name `reversal`), created_by, posted_at, posted_by | Has **no** payment, discount, extra cost, invoice no or document date fields. |
| `StockReceiptItem` | receipt, product, qty_milli (negative in a reversal), cost_price_tiyin, new_sell_price_tiyin?, line_total_tiyin | Several lines can have the same product. There is no unique constraint. |
| `StockMovement` | `AppendOnlyModel`: save() works only on insert, delete() raises. Fields: product, store, qty_milli ≠ 0, type (receipt/sale/refund/adjustment/inventory), ref_type, ref_id, at, created_by | This is the source of truth for stock. |
| `ProductStock` | (product, store) unique, qty_milli | Cache. `record_movement` updates it in the same transaction. `manage.py rebuild_stock` rebuilds it. |
| `InventoryCount` / `InventoryCountItem` | status, scope, category; expected_milli is set at post time, counted_milli | |

**Client** (`apps/pos/lib/data/db/tables/document_tables.dart`, drift `schemaVersion = 3`)

| Table | Fields |
|---|---|
| `stock_receipts` | id, supplier_id?, store_id?, number? (**never filled**: receipts are not pulled), status, total_cost_tiyin, note, created_at, posted_at, posted_by |
| `stock_receipt_items` | id, receipt_id (FK), position, product_id, qty_milli, cost_price_tiyin, new_sell_price_tiyin? |
| `stock_movements` | id, product_id, store_id?, qty_milli, type, ref_type, ref_id, **outbox_event_id**, at |
| `product_stock` (pull) | **PK = product_id only**, store_id, qty_milli |
| `suppliers` (pull) | id, name, phone, note, deleted_at |

### 1.2 Draft vs posted
- **Client draft:** `ReceiptStore` (`lib/data/receipts/receipt_store.dart`). Every edit is written to the DB immediately, and `_recalc` keeps `total_cost_tiyin` up to date. You can delete a draft (`deleteDraft`). No draft ever reaches the server.
- **Client post** (`ReceiptStore.post`, lines 361-434) runs in one drift transaction. It:
  - adds one `stock_movements` row (+qty, type `receipt`, ref `stock_receipt`/receipt id, `outbox_event_id`) per line;
  - sets product cost to the line cost, and sell price if one was given;
  - sets status `posted` with posted_at/by and store;
  - enqueues the outbox event `receipt.posted {id, supplier, note, items:[{product, qty_milli, cost_price_tiyin, new_sell_price_tiyin?}], by}`.
- **Server** `receipt_posted` (`backend/apps/sync/handlers.py:104-112`): `StockReceiptSerializer` create (draft), then `post_receipt` (`services.py:196-232`). That writes the movements, updates cost/sell price, adds `PriceHistory`, and sets status posted. REST supports the same flow (`/stock-receipts/`, `/{id}/post/`).
- **Posted receipts are read-only** on the client: `ReceiptEditor` with `editable: false`. On the server, PATCH and DELETE return `409 receipt_not_draft`.

### 1.3 How stock is derived
- **Server:** the ledger is `StockMovement`, append-only. `ProductStock` is a cache bumped with `F()` inside the same transaction, and a `log_change("stock")` entry lets clients pull it.
- **Client:** stock = `product_stock.qty_milli` (last pulled server value) + Σ local `stock_movements` whose outbox event is NOT `sent`. See `stockQuery` in `lib/data/catalog/product_editor.dart:398-415`.
- Negative stock is allowed and never blocks anything (sync.md, inventory-api.md).

### 1.4 Cancel / reverse
- **Server REST only:** `POST /api/v1/stock-receipts/{id}/reverse/` calls `reverse_receipt` (`services.py:235-277`). It creates a new posted receipt with `reverses = original`, negative items, a negative total and negative `receipt` movements. Prices are not reverted. It returns 409 on `already_reversed`, `receipt_not_posted` and `cannot_reverse_reversal`.
- **Nothing calls it.** The admin app is the platform admin, the POS has no button, and there is no sync event for it.
- **The POS client has no cancel or reverse at all.** The spec says "teskari kirim — keyin".

### 1.5 Cost and price updates
- The policy is **last cost**: `product.cost_price_tiyin` is set to the line cost on every post, on both server and client. There is no weighted average.
- Sell price changes only when `new_sell_price_tiyin` is set. The client sends null when the entered value equals the current price.
- The server writes `PriceHistory` when either price changes.
- Sales store their own snapshot in `SaleItem.cost_tiyin`, so profit reports never re-read receipts. No report uses receipts (`apps/reports` and the POS local reports do not reference them).

### 1.6 Suppliers
- The `Supplier` entity exists: CRUD, `supplier.upserted` event, and a quick-create picker on the POS.
- **Supplier debt, balance or payments do not exist anywhere**: no model, field or event. Nothing has to stay consistent there today.

### 1.7 Multi-device visibility
- Receipts are **not** a pull entity. A receipt posted on device A, through REST, or by the server-side product import (decision 0009) is **not visible** on device B. Only its stock effect arrives, through `stock`.
- The client never learns the receipt `number`.

---

## 2. Design: "edit a posted receipt" (correction = reversal + new version)

### 2.1 Principles
- **Immutability (rule 3):** the original receipt row, its items and its movements are never modified.
- **Edit = correction.** One atomic local transaction creates:
  - **R**, the reversal document: `reverses = V1`, negative items, negative movements;
  - **V2**, the new version: `corrects = V1`, positive items and movements, with the cost/price rules from §2.5;
  - **one** outbox event, `receipt.corrected`.
- Net stock effect = new − old. For 10 → 7: −10 + 7 = **net −3**, so the stock ends up having received +7 in total. Nothing is double-counted, because every movement is applied exactly once and the client's view is "server + unsent", which gets replaced once the event is `sent`.
- **Cancel / void** is the same without V2: a `receipt.reversed` event.
- **The server never rejects a correction because of a conflict.** A rejection would leave the client's local movements permanently out of step with the server. Conflicts resolve as **last writer wins on the head of the chain** and are flagged for the owner to review.

### 2.2 Server changes (Django)

**Migration `inventory/0002_receipt_corrections.py`** (purely additive):
- `StockReceipt.corrects = OneToOneField('self', null=True, blank=True, on_delete=PROTECT, related_name='correction')`
- `StockReceipt.conflict = BooleanField(default=False)`, or record the conflict in `SyncEvent.error` and `note` instead.
- Optional `StockReceipt.client_posted_at = DateTimeField(null=True)`.
- Data migration: write a `ChangeLog(entity="stock_receipt")` row for every existing receipt. These rows get a new txid, so every device receives them on its next pull. This is the backfill; old clients ignore unknown entities (`pull.dart:27` comment).

**Services** (`apps/inventory/services.py`):
- `reverse_receipt(receipt, *, user, note, id=None, at=None)` takes a client id and time.
- New `correct_receipt(original, *, user, data, id, reversal_id, at)`. It is `@transaction.atomic` and runs these steps:
  1. Lock `original`.
  2. If it is a reversal, raise `cannot_correct_reversal`. This case comes from a programming error, not a conflict.
  3. `head = original`. While `head` has a `reversal` and a `correction`, set `head = head.correction` under lock.
  4. If `head != original`, set `conflict = True`.
  5. If `head` is not reversed yet, call `reverse_receipt(head, id=reversal_id if head == original else new_id(), at=at)`.
  6. If `head` was cancelled (reversed with no correction), skip the reversal. Last writer wins: the new version is posted on top.
  7. Create V2 with `id`, `corrects = head`, items and status posted, then post it with the price rules in §2.5. Movements use `at`.
- Idempotency: the `SyncEvent.id` check already covers repeats. On top of that, if `StockReceipt(pk=id)` already exists, return without doing anything. This protects against replay with a different event id.

**Sync handlers** (`apps/sync/handlers.py`):
- `receipt.corrected` payload: `{id, corrects, reversal_id, supplier?, note, items:[{product, qty_milli>0, cost_price_tiyin>=0, new_sell_price_tiyin?}], by, at}`.
  - Managers only.
  - If the original is missing, raise `MissingDependency("stock_receipt", corrects)`, which means pending.
- `receipt.reversed` payload: `{id, reverses, note, by, at}`. If the original is already reversed (by another device), return applied as a no-op. If it was corrected, reverse the head (last writer wins: the user wanted it cancelled).
- `receipt.posted`: accept an optional `at`, used for posted_at and movement `at`. Old clients don't send it, so the server falls back to `now()`.

**REST** (optional, for symmetry and later admin use):
- `POST /stock-receipts/{id}/correct/` calls the same service.
- Serializer gains read-only `corrects`, `correction`, `reversal` and `conflict`. These fields are additive, so old clients are unaffected.

**Pull:** add entity `stock_receipt` with header and items, using the serializer shape. Log a change on receipt post, reversal and correction.

**Tests** (rule 4 and the acceptance criteria):
- 10 → 7 gives net +7. The SUM of movements equals the cache.
- An idempotent duplicate push changes nothing.
- Two devices correct the same receipt: the final state is the last applied version and `conflict` is set.
- Correct after cancel; cancel after correct.
- Correction of a reversal returns 409.
- A correction arriving before the original gives pending, then applied.
- Another tenant's `corrects` or product gives rejected/404.
- Cost/price rules: an old receipt doesn't overwrite a newer cost; sell price is reverted only if unchanged.
- Stock can go negative after a correction.

### 2.3 Client changes (Flutter / drift)

**Schema v4** (`app_database.dart`, `from3To4`), generated with `dart run drift_dev make-migrations` so the `drift_schemas/drift_schema_v4.json` snapshot and its tests come with it:
- `stock_receipts.corrects_id TEXT NULL` and `stock_receipts.reverses_id TEXT NULL`.
- Index `stock_receipts_corrects` and a unique partial index `UNIQUE(reverses_id) WHERE reverses_id IS NOT NULL`, so a receipt can be reversed only once locally.
- Nothing is added to the original row. "Corrected" and "cancelled" are derived from child rows, so the original stays immutable.

**ReceiptStore API:**
1. `startCorrection(String originalId) → String draftId`
   - If a draft with `corrects_id = original` exists, return it.
   - Otherwise copy supplier, note and items into a new draft: qty, cost, `new_sell_price = null`.
   - Merge duplicate product lines. Pulled or imported receipts can contain duplicates, and `addProduct` uses `getSingleOrNull`.
   - Refuse to start in these cases:
     - the original is a reversal;
     - it is already reversed locally;
     - its `receipt.posted` outbox event is `rejected`;
     - it is not posted.
2. The draft is edited with the existing `ReceiptEditor` (autosave). Deleting the draft discards the correction with no stock effect.
3. `postCorrection(draftId, {by, storeId})` runs in **one** `_db.transaction`. It:
   1. re-checks that the original is still correctable;
   2. inserts the reversal R (`reverses_id = V1`, status posted, items with −qty, total −V1.total);
   3. inserts movements `-qty` with `ref_id = R` and `outbox_event_id = E`;
   4. posts the draft V2 (`corrects_id` already set): movements `+qty` with `ref_id = V2` and `outbox_event_id = E`;
   5. updates product prices using §2.5;
   6. enqueues **one** event `receipt.corrected`, id `E`.

   An empty draft is treated as a cancel: ask for confirmation, then call `reverse()`.
4. `reverse(originalId, {by, note})` runs one transaction: R plus negative movements plus a `receipt.reversed` event.
5. Feature gate: show "Tahrirlash" and "Bekor qilish" only when the server advertises `receipt_corrections`. Add a `features` list to the pull response and store it in `local_settings`. An old server would reject the new event type with `unknown_event`, which would cause local divergence.

**Pull applier:** handle `stock_receipt`. Upsert the header with insertOnConflictUpdate, replace the items, and create **no** `stock_movements`, because the server stock already includes them. Never overwrite a local `draft` row.

### 2.4 UI flow
- **List** (`receiving_screen.dart`):
  - Reversal documents (`reverses_id != null`) are hidden from the list.
  - Badges:
    - "Tasdiqlangan" (success);
    - "Tuzatilgan" (neutral) when a posted child with `corrects_id = id` exists;
    - "Bekor qilingan" (danger) when reversed with no correction;
    - "Tuzatish" on corrections;
    - "Tuzatish qoralamasi" on draft corrections.
  - Show the server `number` (K-12) once receipts are pulled.
- **Detail** (posted `ReceiptEditor`):
  - "Tahrirlash" (primary) and "Bekor qilish" (ghost or danger) buttons. They need owner/manager or `requestManagerApproval`, and are disabled when `salesAllowedProvider` is false.
  - If the receipt was corrected, show a banner: "Bu kirim tuzatilgan · Yangi versiyani ochish". Edit and cancel are disabled; the user edits the head instead.
  - If it is a correction, show a link "Asl kirim: <date/number>".
- **Correction draft:** banner "Kirimni tuzatish — asl kirim <date>". The post button reads "Tuzatishni saqlash".
- **Before saving**, show a confirm dialog with:
  - a per-product table: old qty → new qty, Δ;
  - **warnings, which do not block:**
    1. stock will go negative: "Qoldiq manfiy bo'ladi: X (−2)";
    2. the product was counted in an inventory posted after V1: "inventarizatsiyadan keyin tuzatish qoldiqni yana o'zgartiradi";
    3. the receipt is not the latest one for this product, so its cost will not change.
- **Stock history** (`stock_history.dart`): label negative `receipt` movements whose `ref_id` is a reversal document as "Kirim tuzatildi/bekor qilindi". Locally, join `stock_receipts.reverses_id`. On the server, add `ref_kind` to `/sync/stock-movements/`.
- All new strings go into uz, uz-Cyrl and ru `.arb` files. Use only pos_ui components. Add goldens and screenshots at 390×844, 1024×768 and 1440×900.

### 2.5 Recomputing stock and cost
- **Stock:** comes only from movements. The net effect is −old + new. Sales made in between are untouched, so stock = before + new − sold. That can be negative, which is allowed and shown as a warning.
- **Cost (last-cost policy):** for each product P in V2, if V1 is P's **latest** non-reversed posted receipt (by posted_at), set `cost = V2 line cost`. Otherwise leave it, because an old receipt must not overwrite a newer cost.
  - If P was removed in V2 and V1 was its latest receipt, restore the cost from the previous latest receipt line, if one exists. Otherwise leave it.
- **Sell price:** apply V2's `new_sell_price` only if `product.sell_price == V1.new_sell_price` (nobody changed it since) or V1 set no price. Write `PriceHistory` on the server.
- **Server is authoritative.** The client applies the same rule over local data on a best-effort basis, and pull overwrites the product afterwards.
- **Historical sales** keep their `SaleItem.cost_tiyin` snapshot. Profit for sales between V1 and V2 is not restated. Document this in `stock-receipt.md`.

### 2.6 Concurrency and ordering
- **Same device:** outbox order by `created_at` guarantees `receipt.posted(V1)` is applied before `receipt.corrected`.
- **Original pending or failed on the server:** `MissingDependency` makes the correction pending, with the 7-day TTL.
- **Two devices edit V1 offline:** the server orders by arrival. The second correction becomes reverse(V2) + V3. The final state equals the last writer's version, stock is consistent, and the receipt is flagged `conflict`. Each device's local movements turn `sent` and the pulled `stock` replaces them, so the devices converge. Pulled `stock_receipt` rows then show the real chain.
- **Server locking:** `select_for_update` on original and head, with the chain walk under the lock.

### 2.7 Backwards compatibility (rule 10)
- The Django migration is additive (nullable FK and a boolean with a default). Old clients keep sending `receipt.posted` unchanged.
- The new pull entity `stock_receipt` is ignored by old clients (`pull.dart:27`).
- The new client sends `receipt.corrected` only when the server advertises the feature.
- Deploy the server first.

### 2.8 Supplier debt (future)
None exists today. If it is added, model it as an append-only `SupplierLedgerEntry(ref_type='stock_receipt', ref_id, amount_tiyin ±)`.
- A correction then writes a reversing entry (−old total) and a new entry (+new total) in the same transaction.
- Payments are separate entries and are never edited.

### 2.9 Open questions for `docs/QUESTIONS.md`
- Is there a time limit for editing, for example only within the current month?
- Should products counted after V1 be blocked from qty edits, or only warned about?
- Should cancel restore the cost price?

---

## 3. Bugs found

| # | Severity | Where | Root cause | Impact | Fix | Test |
|---|---|---|---|---|---|---|
| B1 | **High** (confirmed by probe) | `backend/apps/sync/handlers.py:96-101` + `apps/core/serializers.py:4-14` (`TenantPKField` excludes `deleted_at`) | An offline `receipt.posted` (and `inventory.posted`) that references a product or supplier soft-deleted on the server in the meantime fails validation. The status is **rejected**, error `validation_error: Invalid pk`. | The whole receipt is lost on the server. The client still counts its movements (rejected ≠ sent), so stock is permanently out of step with the server. The sale handler (`sales/services/sales.py:22`) accepts deleted products, so behaviour is inconsistent. | In the sync handlers, resolve product and supplier including soft-deleted rows. Either use a sync-only serializer with an unfiltered tenant queryset, or set the supplier to null if it was deleted. | push `receipt.posted` for a deleted product or supplier expects `applied` and the stock to increase. |
| B2 | **Medium** (confirmed) | `services.py:197-219` `post_receipt`; handler gives no `at` | Prices are updated by **apply order, not event time**. A receipt posted offline earlier overwrites a newer price set later in the admin or on another device. | The sell price silently reverts and cashiers sell at the old price. The probe set 999 000 then applied an old receipt with 500 000, and the result was 500 000. | Send `at` in the payload. Update the price only if `at` is later than the product's last `PriceHistory.at` (or `price_changed_at`). Always record `PriceHistory`. | An old-dated receipt arriving after a price change leaves the price unchanged. |
| B3 | **Medium** (confirmed) | `handlers.py` / `services.py:200` + `:225` | Receipt `posted_at` and movement `at` are **server time**. The client's posted time is never sent. | Movement history and dates are wrong after offline periods (could be days), and the order relative to inventory counts and sales is distorted. `sale.completed` uses the client `sold_at`, so the two are inconsistent. | Add `at` to the `receipt.posted` and `inventory.posted` payloads (additive) and pass it to `record_movement(at=)` and posted_at. | An event with an old `at` gives `movement.at == at`. |
| B4 | **High** (logic) | `services.py:337-371` `post_inventory` with the offline flow | The server recomputes `expected` from its cache **at apply time**. (a) A sale on another device that happened *before* the count but syncs *after* it is subtracted again, so stock = counted − sale. (b) Sales that happen *after* the count but are applied *before* a late count event are wiped out. | Wrong stock after every offline inventory count in a multi-till shop. | Send the client `at` (B3) and compute `expected = Σ movements with at ≤ count.at`. Movements must carry client time. Or send the client `expected_milli` and apply `counted − expected_client` as a delta, plus a reconciliation note. Write a decision record. | Device B sells (t1) and syncs after device A's count (t2 > t1) is applied; stock should equal counted. |
| B5 | **Medium** | `lib/data/sync/sync_engine.dart:66-77` + `push.dart:62-75` | When the outbox head is in backoff after a network error, `_due` returns `[]`, push "succeeds" and **pull runs**. If the server had already applied the batch (response lost), the pulled `product_stock` includes those movements while the local movements are still `pending`. | **Double-counted stock** for up to 5 minutes (max backoff). Inventory posted on the client in that window computes a wrong `expected`. | Skip pull while any outbox event is `pending` with `attempts > 0`. Better: have pull return acked event ids, so they are marked `sent` in the same transaction that applies stock. | `sync_engine_test`: response lost → backoff → syncOnce should not pull; or stock stays unchanged. |
| B6 | Medium | Same window, `pull.dart:182-210` `_upsertProduct` | Pull overwrites local product cost/sell price set by a not-yet-acked `receipt.posted` or `product.upserted`. | Cashiers sell at the old price and sale snapshots record the old cost until the event is applied. | Same as B5. Also skip product upserts for products with an unsent price-changing event. | pull_test |
| B7 | Low-Med | `product_editor.dart:398-415` `stockQuery` | Movements of **rejected** events are counted forever (`status != 'sent'`). | The local stock permanently differs from the server. Only the "N rejected" status hint shows it. | Count only `pending` (and null) events, and show rejected events in an admin warning. Or keep counting but surface the divergence. This is a business choice; once B1 is fixed, rejections are rare. | |
| B8 | Low | `reference_tables.dart:135-143` | `product_stock` PK is `product_id` only, while the server is per (product, store). `stockQuery` joins on the product only. | With a second store (future), rows overwrite each other. | Use PK (product_id, store_id) and filter by the device store. | |
| B9 | Low | `handlers.py:96-101` | The sync payload has no `store`, so the server uses `default_store(tenant)` instead of `device.store`. The local movements use the device store. | Wrong store once there are several stores. | Use `device.store` in `_post_document`. | |
| B10 | Low | `receipt_editor.dart:125-162` | `_post` has no `try/catch`. `ReceiptEmptyException` (race) or a DB error becomes an unhandled async error with no toast. | Silent failure. | Catch the error and show a toast (l10n). | widget test |
| B11 | Low (UX) | `receipt_store.dart:155-176`, `receipt_editor.dart:544-547` | A posted receipt shows `currentSellTiyin` (today's price), not the price at posting, when no new price was set. | Confusing history. | Show only `new_sell_price` for posted receipts, or snapshot the price at post. | |
| B12 | Low (UX) | `receiving_screen.dart` | Receipts from other devices, the server import or REST are not visible, and `number` is never filled. | Cannot find or edit them across devices; no K-number shown. | Add the `stock_receipt` pull entity (§2.2). | |
| B13 | Low (perf) | `count_store.dart:180` + `watch` | `load()` runs the full `stockQuery` over all products on every change to items, movements or stock. | Slow with 5k+ products while scanning. | Query stock only for the count's products plus the uncounted list once, or debounce. | |
| B14 | Info | `receipt_store.dart:215-253` `addProduct` | `getSingleOrNull` throws if two lines share a product. This can't happen today, but **will** when corrections copy server or import receipts with duplicate lines. | Crash in correction drafts. | Merge on copy, or use `.get().firstOrNull`. | |
| B15 | Info | `services.py:235-277` | `reverse_receipt` exists but no UI or event uses it. A REST reversal is invisible to POS clients except through stock. | | Covered by §2. | |

Probe test file: `scratchpad/probe/test_probe_receipts.py`. B1 (product and supplier), B2 and B3 all reproduced.
