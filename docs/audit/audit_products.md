# Product lifecycle audit: POS (backend + Flutter kassa)

Date: 2026-10-15. Scope: product create/edit/list/search/sync/print/receiving/sale, plus product images.
Method: I read the specs (`products.md`, `catalog-api.md`, `sync.md`, `sync-api.md`, `data-model.md`) and the code. I reproduced the backend findings with a throwaway pytest file in the scratchpad (`scratchpad/repro/test_product_repro.py`, run against the dockerised Postgres). I checked search normalisation by running a copy of `search_key.dart` under `dart run` (`scratchpad/dart/main.dart`). The existing `apps/catalog` and `apps/sync` tests pass (144 tests). No project files were modified.

## Summary table

| # | Pri | Finding | Status |
|---|---|---|---|
| 1 | P0 | When the server rejects a `product.upserted` event, the product stays on the kassa only. Every later sale, receipt or count of that product is then also rejected ("Unknown product"), so that money and stock never reach the server | Reproduced |
| 2 | P0 (rare trigger, total impact) | A NUL character (`\u0000`) in any event payload makes `/sync/push/` return 500. The whole batch fails and the device's outbox is blocked permanently | Reproduced |
| 3 | P1 | The kassa does not limit the product name to 200 characters (server limit) or the barcode list to 20 items. Longer values are rejected and lead into #1 | Reproduced (server side) |
| 4 | P1 | `product.upserted` sends a full snapshot, so a stale offline edit overwrites newer server prices and barcodes (lost update) | Reproduced |
| 5 | P1 | After a rejected product edit, the kassa's local product stays different from the server copy indefinitely (server-wins is not enforced) | Code reading |
| 6 | P1 | The product card's save only handles `InvalidProductException`. Any other error leaves the Save button disabled with no message | Code reading |
| 7 | P1 | The PLU uniqueness check uses `getSingleOrNull`, which throws `StateError` when two or more local products share a PLU (possible after offline races) | Code reading |
| 8 | P1 | A category deleted on the server while a kassa was offline makes product saves from that kassa get rejected, leading into #1 | Reproduced |
| 9 | P2 | Search key: `´` and some other apostrophe look-alikes are not handled; typographic quotes and emoji are treated as letters; Cyrillic `е`/`ц` mismatch Latin `ye`/`ts`; the stored key has no version | Reproduced (Dart) |
| 10 | P2 | Server `?search=` uses plain `icontains` with no normalisation, so it behaves differently from the kassa | Code reading |
| 11 | P2 | ESC/POS CP866: `«» “” „ ´ …`, emoji and Latin-1 letters print as `?`. Control characters go to the printer raw. Width and wrapping count UTF-16 units | Code reading |
| 12 | P2 | The server accepts `\n` and `\t` in names and does no whitespace or NFC normalisation, and the Excel import can bring such names in | Reproduced |
| 13 | P2 | On the API, `plu_code: ""` is stored as `""`, so a second blank PLU gets `409 plu_taken` | Reproduced |
| 14 | P2 | No warning anywhere for duplicate names. Re-importing rows without a barcode creates duplicate products | Code reading |
| 15 | P2 | The `PosDialog` title (the product name) has no `maxLines`, so long names push the form down | Code reading |
| 16 | P2 | If `ProductEditor.load()` returns null, the card opens as a blank "new product" (risk of creating a duplicate) | Code reading |
| 17 | P2 | Stock movements from rejected sales keep counting in local stock forever | Code reading |
| 18 | P2 | The server allows `sell_price_tiyin = 0`, while the kassa and spec require more than 0 | Code reading |
| — | info | Product images: no support exists anywhere. The implementation plan is at the end | — |

What is already correct (so nobody re-checks it):
- **Uzbek and Cyrillic text in names.** The server stores `Yogʻ «Oltin»`, `Oʻrik`, `‘Musaffo’`, `Ёғ кунгабоқар` and `Choy “Ahmad” 🍵` unchanged. The DRF `CharField` trims leading and trailing spaces, and so does the kassa (`d.name.trim()`).
- **Search for `yog'`.** It finds `Yogʻ`, `yog\``, `Ёғ` (all produce the key `yog`). `ўрик` and `O‘rik` both produce `orik`.
- **Printing `ʻ ʼ ‘ ’`.** `Receipt.plain()` (`apps/pos/lib/features/printing/receipt.dart:318-322`) maps them to `'`. It also maps NBSP, U+202F and U+2007 to a space and `− – —` to `-`. The CP866 encoder maps Uzbek `Ў Қ Ғ Ҳ` to `У К Г Х`, so these do not print as `?`.
- **Edit path.** The card loads from local `products` and `product_barcodes`; the list (`product_list.dart:125-160`), the POS catalog (`product_catalog.dart:183-233`) and the editor all read the same local tables. On the server, `_upsert` updates partially, and the kassa sends every field, so the name and the other fields are kept. There is no `name`/`title` mapping mismatch.
- **Unit, cost, sell price, barcode and stock wiring is consistent:**
  - **Create and edit.** `product_editor.dart:322-390` and the payload match `ProductSerializer`.
  - **Pull.** `pull.dart` `_upsertProduct` replaces the barcode list, first barcode primary.
  - **Receiving.** It sets the cost price and an optional new sell price identically on the kassa (`data/receipts/receipt_store.dart:390-401`) and on the server (`backend/apps/inventory/services.py:216-229`).
  - **Sale.** It uses the catalog's `priceTiyin`/`costTiyin`, and the server cross-checks line totals.
  - **Stock.** It is computed by `stockQuery` (server value plus unsent movements).
- **Barcode rules match.** `Barcodes.normalize/check` (Dart) and `barcodes.py` behave the same: 4–64 visible ASCII characters, EAN/UPC check digit, leading zeros kept, uniqueness among a tenant's barcodes that are not deleted (inactive products included).

---

## P0-1: A rejected `product.upserted` orphans the product, and every later sale of it is rejected too

**Location**
- `backend/apps/sync/handlers.py:44-56,91-92`: `_upsert` runs `ProductSerializer` with `is_valid(raise_exception=True)`. Any validation error or `DomainError` marks the event `rejected`.
- `backend/apps/catalog/serializers.py:130-161` (`validate`): raises `409 barcode_taken` or `409 plu_taken` (DomainError).
- `backend/apps/sales/services/sales.py:24-26`: `if product is None: raise invalid(CODE, "Unknown product.")`. This is a DomainError, so the sale is **rejected**, not `pending`. Receipts (`StockReceiptSerializer` product PK) and inventory counts behave the same way.
- `apps/pos/lib/data/sync/push.dart:141-153`: on `rejected` the kassa only stores `last_error`. The status bar shows a count ("N ta yozuv qabul qilinmadi") with no detail and no way to fix it.

**Root cause.** The kassa saves the product locally first (by design, offline-first). Its validation runs only against the **local** catalog. In a shop with several kassas, or after any offline period, the server can still refuse the product:
- **`barcode_taken`:** kassa 1 creates "Pepsi 1l" with barcode X, and kassa 2 scans X before its next pull, finds nothing, and creates a new product with X. This is a very realistic sequence when new goods arrive.
- **`plu_taken`:** the same race for PLU codes.
- **Name longer than 200 characters** (#3), **more than 20 barcodes** (#3), or a **category deleted on the server** (#8).

The product then exists only on that kassa. Cashiers keep selling it. Every `sale.completed` containing it is rejected as a whole, including the other lines, the payments and any debt entry. The same applies to `receipt.posted` and `inventory.posted`.

**Repro** (`test_barcode_race_two_devices_then_sales_lost`). The second device's product gets `rejected barcode_taken`. Its sale then gets `{'status': 'rejected', 'error': {'code': 'invalid_sale', 'message': 'Unknown product.'}}`.

**User impact.** Server reports, Z-reports, cash totals, customer debts and stock are missing those sales permanently, with no way to recover them in the UI. To the owner this looks like "some actions throw errors / sales disappear".

**Fix** (several layers; do at least (a) and (b)):
- **(a) Server: never reject a product for a recoverable conflict.**
  - In `product_upserted`, catch `barcode_taken` and `plu_taken`. Apply the product **without** the conflicting barcodes, or with `plu_code=None`.
  - Record the dropped values in `SyncEvent.error` as warnings, for example status `applied` with `warnings: [{code: 'barcode_taken', barcode, product}]` (a new optional result field, backward compatible).
  - Treat a missing or deleted `category` as `None`.
  - Normalise and truncate the name to 200 code points (see #12).
  - Keep rejecting only for auth or permission problems and for malformed payloads.
- **(b) Server: sales should wait for the product.** In `sales.py:_items`, `receipt.posted` and `inventory.posted`, an unknown product id should raise `MissingDependency("product", id)`, so the event is `pending` and retried for 7 days, instead of `invalid_sale`. Cross-device ordering then heals itself.
- **(c) Kassa: make rejections fixable.**
  - Add a screen that lists rejected outbox events in plain Uzbek, for example "«Pepsi 1l» saqlanmadi: shtrix-kod 478… «Pepsi 1l (kassa1)» tovarida".
  - Offer "Open product" so the user can correct the product, which re-enqueues a new event.
  - When online, check new barcodes against the server before saving. A device-token `by-barcode` endpoint would be needed; it is optional.
- **(d) Spec.** Update `sync-api.md` and `catalog-api.md` with the "apply with warnings" rule. Add a decision record, `docs/decisions/0010-catalog-conflicts-never-lose-sales.md`.

**How to test**
- Backend: make my repro a real test. Two devices create products with the same barcode; expect the second to be `applied` with the barcode dropped and a warning. The device-2 sale is then `applied`.
- Backend: a sale referencing an unknown product is `pending`; after the product arrives it becomes `applied`.
- Flutter: an `OutboxPusher` test where the result is `rejected` and the UI list shows the event.

## P0-2: NUL (`\u0000`) in any payload makes push return 500, and the outbox stays blocked permanently

**Location**
- `backend/apps/sync/services.py:24-25`: `_json_safe` does not sanitise strings.
- `backend/apps/sync/services.py:102-114`: `SyncEvent(... payload=...)` and `event.save(force_insert=True)` run **outside** any try block.
- Kassa side: `apps/pos/lib/data/sync/push.dart:113-117` postpones the whole batch on an `ApiFailure`. The rule "Navbat boshi kutayotgan bo'lsa, hech narsa yuborilmaydi" (nothing is sent while the head of the queue is waiting) then blocks every later event.
- `apps/pos/lib/data/sync/sync_engine.dart:66-79`: an exception thrown by push also skips the pull in that cycle.

**Root cause.** PostgreSQL `jsonb` cannot store `\u0000`, so psycopg raises `UntranslatableCharacter`. This surfaces as Django `DataError`, which becomes HTTP 500 for the whole request.

**Repro** (`test_name_nul_rejected`): `django.db.utils.DataError: unsupported Unicode escape sequence ... \u0000 cannot be converted to text`, and the push returns 500.

**User impact.** One bad character, for example pasted text or a misconfigured scanner suffix in a name or note field, stops that kassa from syncing **anything** again: sales, shifts, debts. It retries every 5 minutes forever. The status bar shows "offline".

**Fix**
- Server:
  - Validate per event inside the loop. Wrap the `SyncEvent` creation in `try/except (DataError, ValueError)` with a savepoint, and mark that event `rejected` with code `invalid_payload`.
  - Better, strip `\x00` recursively in `_json_safe`. For example: `json.loads(json.dumps(value, default=str).replace('\\u0000', ''))`, or walk dicts and lists and remove `\x00` from strings.
  - Also add `PushRequestSerializer` validation that rejects NUL per event, not for the whole batch.
- Kassa: strip C0 control characters (`[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]`) in all free-text inputs. A default `inputFormatter` in `PosTextField` (`packages/ui`) is a good place. Also sanitise in `ProductEditor.save`.

**How to test.** Push a batch containing `[valid sale, product with name "A\u0000"]`. Expect 200: the sale `applied` and the product `rejected invalid_payload`, or `applied` with the NUL stripped.

## P1-3: No client-side maximum length for the name or the barcode count, so the server rejects (leading into #1)

**Location**
- `apps/pos/lib/features/products/product_card.dart:390-396`: the `PosTextField` for the name has no `maxLength` or formatter.
- `apps/pos/lib/data/catalog/product_editor.dart:205-209`: only an emptiness check.
- `backend/apps/catalog/models.py:89`: `max_length=200`.
- `backend/apps/catalog/serializers.py:77-79`: `barcodes ... max_length=20`.
- `PosTextField` in `packages/ui` exposes no `maxLength` at all (grep finds none outside the PIN pad). The same gap exists for customer and supplier names (`full_name` and `name` are 200 on the server).

**Repro**
- A 201-character name is rejected: `{'name': ['Ensure this field has no more than 200 characters.']}`.
- 199 × `A` plus the family emoji 👨‍👩‍👧‍👦 is also rejected. That is 1 grapheme but 7 code points, so Flutter's `maxLength`, which counts graphemes, would **not** prevent it.
- 21 barcodes are rejected: `Ensure this field has no more than 20 elements.`

**User impact.** Users paste long names from supplier invoices. The product saves locally, then gets rejected on the server, and its sales are lost (#1).

**Fix**
- Add `ProductProblemCode.tooLong` and a `ProductField.name` check `name.runes.length > 200` (count **code points**, as Python does).
- Add a formatter that limits by runes (not Flutter's grapheme-based `maxLength`) and expose `maxLength`/`inputFormatters` on `PosTextField`.
- Limit barcodes to 20, with a `ProductProblemCode.tooManyBarcodes` check.
- Add l10n strings in uz, uz-Cyrl and ru.
- Put the shared limits in one constants file mirrored from the server: `ProductLimits.nameMax = 200`, `barcodesMax = 20`.

**How to test.** `ProductEditor.validate` with 201 code points, and with 199 characters plus the family emoji, returns `tooLong`. A widget test shows the error under the field.

## P1-4: Full-snapshot upsert loses newer server changes

**Location**
- `apps/pos/lib/data/catalog/product_editor.dart:367-387`: the payload always contains every field and the full barcode list.
- `backend/apps/catalog/services.py:33-58`: `save_product` assigns every key it receives.
- `set_barcodes` soft-deletes barcodes that are not in the list.

**Root cause.** The specs say "server wins" for the catalog, but the event carries the kassa's whole (possibly stale) copy. A kassa that was offline and only renamed a product also sends its old price and old barcode list.

**Repro** (`test_stale_snapshot_overwrites_server_price`). The server price was set to 500 000 after the kassa's last pull. A stale rename event from the kassa brings it back to **400 000**. A misleading `PriceHistory` row is also written under the kassa manager's name. Barcodes added on the server meanwhile are soft-deleted by the same mechanism.

**User impact.** The owner's price changes or newly added barcodes silently revert after an offline kassa reconnects. Scans of the removed barcode then fail.

**Fix**
- In `ProductEditor`, keep the loaded `ProductDraft` as the base and send only the fields that changed, plus `id` and `by`. For barcodes, send the list only if it changed, or better, send `barcodes_added`/`barcodes_removed`.
- The server already uses `partial=True` for existing products, so sending fewer keys is backward compatible. Older kassas keep sending full snapshots.
- Optionally send `base_updated_at`. The server then ignores price fields when `product.updated_at > base_updated_at` and the price differs, and returns a warning.

**How to test.** Backend: a stale partial event (name only) keeps the server price. Flutter: a `ProductEditor.save` unit test checks that the payload contains only the changed keys.

## P1-5: Rejected product edits leave the local catalog different from the server

**Location.** `push.dart:141-153` only marks the event; the kassa never restores the server state. `pull.dart` overwrites a product only when the server's `ChangeLog` has a new entry for it.

**Impact.** After a rejected edit, the product keeps the wrong name, price or barcode **on that kassa only**, until somebody edits it elsewhere. Rejected barcodes stay attached locally to two products. `ProductCatalog._byBarcode` then returns whichever product loaded last, so scans are nondeterministic.

**Fix.** In `apps/sync/services.py:_apply`, when a `*.upserted` event is rejected and the object exists, call `log_change(tenant, entity, id)` so that the next pull re-sends the server truth. For a product that does not exist on the server, see #1(c).

**Test.** Push a rejected update, then pull: the response contains the product with the server's values.

## P1-6: The product card's save swallows unexpected errors

**Location.** `apps/pos/lib/features/products/product_card.dart:262-274`: `try { await editor.save(...) } on InvalidProductException`. There is no `catch (Object)`. `_busy` stays `true`, so the Save and Deactivate buttons stay disabled with no message. `_check()` (lines 167-178) is also called `unawaited` without handling errors.

**Triggers**
- A `SqliteException UNIQUE constraint failed: product_barcodes.barcode`. `ProductEditor.save` (lines 356-366) uses a plain `insert`, and `ProductBarcodes`' primary key is `barcode` (`reference_tables.dart:94-104`). A background pull every 60 s can insert the same barcode for another product between `validate()` and the transaction.
- A `StateError` from #7.
- Disk-full or I/O errors.

**User impact.** "I press Save and nothing happens"; the user has to close and reopen the dialog.

**Fix**
- Add `catch (Object e, st)`: reset `_busy`, show `showPosToast(context, message: l10n.errorGeneric, tone: PosTone.danger)`, and log the error.
- In `ProductEditor.save`, re-run the barcode and PLU checks **inside** the transaction, and turn a SQLite unique violation into `InvalidProductException(barcodeTaken)`.

**Test.** A widget test with a fake `ProductEditor` whose `save` throws `StateError`: the button becomes enabled again and a toast is shown.

## P1-7: PLU check throws when two local products already share a PLU

**Location.** `apps/pos/lib/data/catalog/product_editor.dart:289-300`: `(_db.select(_db.products)..where(...)).getSingleOrNull()`. Drift's `getSingleOrNull` throws `StateError` when more than one row matches. The local `products_plu` index is not unique (`reference_tables.dart:64`).

**How duplicates appear.** Kassa A (offline) gives PLU 00012 to product P1. Kassa B gives the same PLU to P2 and syncs. A's pull brings P2 in, and A's P1 push is rejected (`plu_taken`). A now has two active products with 00012. Creating a third product with 00012, or changing any product's PLU to it, throws inside `validate()`. Through #6, the card then freezes.

**Fix.** Add `..limit(1)` before `getSingleOrNull()`, or use `.get()` and take the first row.

**Test.** Unit test: insert two active products with the same PLU, then `validate` a new draft with that PLU. Expect a `pluTaken` problem, not an exception.

## P1-8: A category deleted while a kassa was offline gets the product rejected

**Location.** `backend/apps/core/serializers.py:4-13`: `TenantPKField` excludes soft-deleted objects. `ProductSerializer.category` uses it (`catalog/serializers.py:72`). Kassa side: the card keeps `draft.categoryId` even when the category no longer appears in the chips (`product_card.dart`, chips built from `productCategoriesProvider`, which filters out deleted ones).

**Repro** (`test_deleted_category_rejects_product`): `{'category': ['Invalid pk "…" - object does not exist.']}`, status rejected.

**Fix**
- Server: in `product_upserted`, if the category is missing or deleted, replace it with `None` and add a warning.
- Kassa: in `_load` and `_collect`, clear `categoryId` when it is not among the active categories.

**Test.** The backend repro becomes `applied` with `category=None`.

## P2-9: Search-key normalisation gaps (`apps/pos/lib/core/text/search_key.dart`)

Results from running the real `SearchKey.of` in Dart:
```
o´rik            -> "o rik"     (U+00B4 not treated as tutuq; `orik`/`o'rik` do NOT find it)
Choy “Ahmad”     -> "cxoy “axmad”"  (curly quotes treated as letters, line 81: rune >= 0xC0)
🍎 Olma          -> "🍎 olma"    (emoji kept; sorts after z)
***              -> ""          (unfindable by name)
Ер ёнғоқ         -> "er yongoq" ; query "yer" -> not found
Пицца            -> "pissa"     ; query "pitsa" -> not found
```
- **Line 52.** `_apostrophes` lacks `´` (U+00B4, common on some keyboards), `ʹ` (U+02B9), `′` (U+2032), `＇` (U+FF07) and `‛` (U+201B).
- **Lines 77-81.** `_isLetterOrDigit` treats every code point at or above U+00C0 as a letter. That includes general punctuation (U+2000–U+206F: “ ” „ … – —), `«»` handled only by accident (they are below U+00C0), `№`, and emoji. Word-start ranking (`product_catalog.dart:169-171`) then misses `“Ahmad”`, and sorting by `searchKey` (`products_screen.dart:154-162`, `product_catalog.dart:98-99`) puts quoted or emoji-first names after Z.
- **Transliteration.** Uzbek Cyrillic `е` at the start of a word is `ye`, and `ц` is `ts`. The current mapping (`е→e`, `ц→s`) does not match Latin input such as "yer" or "pitsa".
- **Stored key.** `products.search_key` is written by `ProductEditor.save` and `PullApplier`, and read by the product list (`product_list.dart:148-150`). The POS catalog, however, recomputes the key from the name. Any future change to `SearchKey` leaves the stored keys stale, so the list and the POS screen would search differently. There is no versioning or backfill migration.

**Fix**
- Extend `_apostrophes`. Treat Unicode punctuation (U+2000–U+206F, U+00A0–U+00BF, U+3000–U+303F) and symbols as separators: use `RegExp(r'[\p{L}\p{N}]', unicode: true)` to decide what is a letter or digit.
- Map word-initial `е` to `ye` (or index both variants).
- For `ц`, map to `ts` on both the Cyrillic side and the Latin side.
- Add `SearchKey.version` and recompute `search_key` on start-up when the version changes (store the version in `local_settings`). Alternatively, stop storing the key and compute it in memory as `ProductCatalog` does.
- Keep a shared fixture, `testdata/search_key.json`, used by both the Dart tests and a future Python port (#10).

**Test.** Extend `test/core/text/search_key_test.dart` with the cases above, including the sort order.

## P2-10: Server search is not normalised

**Location.** `backend/apps/catalog/views.py:91-96`: `Q(name__icontains=search)`. A search for `yog'` does not find `Yogʻ`, and Latin does not find Cyrillic. No UI uses this today (the admin app is platform-level), but `catalog-api.md` promises name search. **Fix:** add a `Product.search_key` column computed by a Python port of `SearchKey` (sharing the fixture from #9), and filter with `search_key__contains` on each token.

## P2-11: ESC/POS printing of special characters

**Location.** `apps/pos/lib/features/printing/escpos.dart:88-117` (`_cp866`) and `receipt.dart:318-322` (`plain`), `326-371` (`_pair`, `wrap`).
- **Handled correctly:** `ʻ ʼ ‘ ’ \`` become `'`; NBSP, U+202F and U+2007 become a space; dashes become `-`; Uzbek Cyrillic letters are approximated; `№` maps to 0xFC.
- **Printed as `?` in CP866:**
  - `« »` (U+00AB/BB, frequent in shop names and in Russian-style quoting) and `“ ” „`;
  - `´`, `…`, `×`;
  - Latin-1 letters (`é`, `ü`), emoji and combining marks.
- **Control characters below 0x20** in names or the receipt header (for example from an import with tabs or `ESC`) are written raw (`if (r < 0x80) return r;`). Newlines and tabs are absorbed by `wrap` (it splits on `\s+`), but `ESC`/`GS` reach the printer and act as commands, giving garbled output.
- **Width.** `wrap` and `_pair` use `String.length`, which counts UTF-16 units. An emoji counts 2 but prints 1 `?`, and a combining mark counts 1 but prints `?`, so columns shift. `substring` can also split a surrogate pair, giving `??`.
- **UTF-8 mode** (`PrinterEncoding.utf8`) sends no code-page or UTF-8 enable command. Most cheap 58/80 mm printers print mojibake in that mode. It is a settings choice, but the settings panel should warn about it.

**Fix**
- Extend `plain()`: `«»“”„‟` → `"`, `´′` → `'`, `…` → `...`, `×` → `x`. Remove C0 control characters and DEL.
- Optionally transliterate Latin-1 accented letters to ASCII.
- In `wrap` and `_pair`, iterate by `runes` (or `characters`) so width and splitting are code-point-safe.

**Test.** `escpos_test.dart`: `EscPos.encode(Receipt.plain('«Oltin» “Ahmad” o´rik\x1b'), cp866)` contains no `0x3F` for the quotes and no `0x1B`. A `wrap` test with emoji at the boundary.

## P2-12: Names are not normalised on the server (newlines, tabs, NFC, double spaces)

**Location.** `ProductSerializer` (the DRF default only trims the ends). `backend/apps/catalog/importing.py:83-97` (`_cell` strips only the ends) and `271-275`.

**Repro.** `'Tab\tichida'` and `'Yangi\nqator'` are stored as-is.

**Impact.** An Excel cell with Alt+Enter becomes a product name containing a newline. The kassa's single-line field cannot show or edit it properly, and the list, receipt and CSV order list are affected. NFD (decomposed) input from some keyboards does not match NFC search.

**Fix.** Add `validate_name` in `ProductSerializer` and use the same helper in the import: `unicodedata.normalize('NFC', s)`, remove control characters, collapse whitespace runs to a single space, then strip. Do the same in `ProductEditor.save`. The server and the kassa then store identical strings.

## P2-13: `plu_code=""` through the REST API

**Location.** `backend/apps/catalog/models.py:109-111` (`null=True, blank=True`) and the unique constraint at lines 129-133 (`plu_code__isnull=False`). DRF accepts `""` and stores `""`.

**Repro** (`test_api_blank_plu_twice`). The first save stores `''`; the second gets `plu_taken`.

The kassa sends `null`, so it is unaffected, but API, import and admin clients would hit this. **Fix:** `validate_plu_code` returns `None` for a blank value (and `ikpu_code` stays `""`, which is fine).

## P2-14: Duplicate names

Neither the kassa nor the server warns about an existing product with the same normalised name. The import updates only by barcode (`importing.py:255-262, 316-317`), so re-importing a sheet without barcodes doubles the catalog. **Fix:** in the card, show a non-blocking hint such as "«X» nomli tovar bor" when `SearchKey.of(name)` equals another active product's key. In the import, match rows without a barcode by normalised name and report them as "updates".

## P2-15: Long name in the dialog title

`packages/ui/lib/src/components/pos_dialog.dart:63-69`: the title is `Text(title)` with no `maxLines`, and it sits outside the scroll view (the scroll view is at line 83). The product card passes `draft.name` (`product_card.dart:382`), so a 200-character name in the H2 style takes about 8 lines on a phone. **Fix:** `maxLines: 2, overflow: TextOverflow.ellipsis`. Add a golden test with a long name.

## P2-16: Card for a missing product opens as "new"

`product_card.dart:131-134`: `load(id) ?? const ProductDraft()` gives a blank draft with `id == null`. If a pull deleted the product while the list was open, saving creates a **new** product. **Fix:** if `load` returns null, close the dialog and show "Tovar topilmadi".

## P2-17: Local stock keeps rejected movements

`product_editor.dart:399-415` (`stockQuery`) adds movements whose outbox event has `status != 'sent'`, which includes `rejected`. The kassa then shows stock that the server will never have. Decide the rule in a spec: either exclude `rejected` events, or show them as "not accepted".

## P2-18: Price 0 rule differs between server and kassa

`catalog/serializers.py:74` (`money_field()` with min 0) and the model's `MinValueValidator(0)`. The spec and the kassa require `sell_price > 0`. This is harmless because the server is more permissive, but the API and import accept 0, and such products are not sellable at the kassa (`sellable` requires `priceTiyin > 0`).

---

## Product images: current state

There is **no** image support anywhere:
- No `ImageField` or `FileField` on any model, and no `MEDIA_ROOT`/`MEDIA_URL` in `backend/config/settings/*.py` (only `STATIC_ROOT`).
- No Pillow in `backend/pyproject.toml`.
- No media volume in `docker-compose.yml` or `docker-compose.prod.yml`, and `deploy/Caddyfile` serves only `/static/*`. `deploy/backup.sh` dumps only Postgres.
- On the kassa, there is no image column in the Drift `Products` table (`reference_tables.dart:67-91`).
- `file_picker ^13.1.0` is already a dependency (used for the import), and `path_provider` is present. There is no `image_picker`, no `image` package and no network-image cache.
- The only multipart upload with the device token is the product import (`backend/apps/sync/imports.py`, `MultiPartParser`). It is a good template.

## Product images: implementation plan (offline-first, tenant-isolated)

### Decisions (record as `docs/decisions/0010-product-images.md`, spec `docs/specs/product-images.md`)
1. **The image is an immutable object with a kassa-generated UUIDv7.** Replacing an image creates a new id, and the product points to the current one. Every URL and file is therefore content-stable and can be cached forever.
2. **Binary data never goes through the JSON outbox.** A separate upload queue table on the kassa handles it. The outbox stays small and NUL-safe, and pushes stay fast.
3. **A product never depends on its image.** `product.upserted` must never become `pending` or `rejected` because of an image (see P0-1: sales of the product would be lost). The upload endpoint attaches the image to the product itself.
4. **The kassa resizes before storing.** Longest side 800 px, JPEG quality 80, EXIF removed, roughly 50–150 KB. The server re-encodes again and makes a 200 px thumbnail.
5. **Tenant isolation.** Files are served by an authenticated Django view (device token or JWT) with a tenant check, not by a public `file_server`. Rule 4: add a "boshqa tenant ko'ra olmaydi" (another tenant cannot see it) test.

### Backend
- **Dependencies.** `uv add pillow`. Set `Image.MAX_IMAGE_PIXELS = 40_000_000` to guard against decompression bombs.
- **Settings** (`base.py`): `MEDIA_ROOT = env("MEDIA_ROOT", BASE_DIR / "media")`, `MEDIA_URL = "/media/"` (unused publicly), and `DATA_UPLOAD_MAX_MEMORY_SIZE`/`FILE_UPLOAD_MAX_MEMORY_SIZE` around 6 MB. In `test.py`, use a `tmp_path` `MEDIA_ROOT` or the in-memory storage (`STORAGES["default"] = {"BACKEND": "django.core.files.storage.InMemoryStorage"}`).
- **Model** (in `apps/catalog/models.py`):
  ```python
  class ProductImage(TenantScopedModel, SoftDeleteModel):
      id = UUIDField(primary_key=True)            # client UUIDv7
      product = FK(Product, PROTECT, related_name="images")
      file = ImageField(upload_to=image_path)     # t/<tenant>/p/<id>.jpg
      thumb = ImageField(upload_to=thumb_path)    # t/<tenant>/p/<id>_t.jpg
      sha256 = CharField(64); width/height/bytes = IntegerField
      uploaded_by = FK(User, null=True)
  Product.image = FK(ProductImage, null=True, blank=True, SET_NULL, related_name="+")
  ```
  The migration only adds nullable fields, which is backward compatible (rule 10).
- **Upload endpoint** (device token): `PUT /api/v1/sync/product-images/{id}/`, multipart with `file`, `product` and `by`.
  - Authorisation: `by` must be the owner or a manager, as for `product.upserted`.
  - The product must belong to `device.tenant`. If it is not there yet, return `409 product_missing`; the kassa retries after its outbox is drained.
  - Idempotent: if the same `id` exists with the same `sha256`, return `200` as a duplicate.
  - Validate with Pillow (`Image.open().verify()`). Allow only JPEG, PNG and WebP, at most 5 MB and 4096 px. Apply `ImageOps.exif_transpose`, re-encode to JPEG at 800 px, and write the 200 px thumbnail.
  - Then set `product.image = img` and `product.save(update_fields=["image","updated_at"])`. The `post_save` signal logs a `ChangeLog` entry, so other kassas receive the change in their pull.
  - Removing the image: `DELETE /api/v1/sync/product-images/{id}/`, which soft-deletes the image and sets `product.image=None` if it is still the current one.
  - JWT twin endpoints for the owner and manager UI: `POST/DELETE /api/v1/products/{id}/image/`.
- **Download endpoint:** `GET /api/v1/sync/product-images/{id}/?size=thumb|full` (device token or JWT).
  - Filter by `tenant_id=request tenant`; anything else returns `404`.
  - Return a `FileResponse` with `Cache-Control: private, max-age=31536000, immutable` and an `ETag` equal to the sha256.
  - Later optimisation: a Caddy `forward_auth` or `X-Accel`-style handoff.
- **Serializer.** In `ProductSerializer`, add a read-only `image: {id, sha256, width, height} | null`. Pull uses the same serializer, so kassas receive it automatically. Old kassas ignore the unknown key: `PullApplier` reads only known keys.
- **`product.upserted` does not touch the image.** Leave the field read-only so that old snapshots (#4) cannot clear it.
- **Infra:**
  - In `docker-compose.yml` and `docker-compose.prod.yml`, add a `media:/app/media` volume to the backend.
  - `deploy/backup.sh` and `restore.sh`: tar the media volume alongside `pg_dump`, using the same retention.
  - In the Caddyfile, set `request_body { max_size 8MB }` in the API site block. `/media` stays unexposed.
- **Tests** (pytest):
  - Upload, then pull returns `image.id`.
  - An idempotent re-upload returns duplicate.
  - A cashier's `by` gives 403. A non-image file and an oversized file give 400.
  - A device of another tenant gets 404 on both the download and the upload (product not visible).
  - `409 product_missing` for an unknown product.
  - An old-style `product.upserted` without `image` keeps the image.
  - Deleting the image clears it.
- **OpenAPI.** Run `make api-clients` to regenerate the Dart client.

### Flutter kassa (`apps/pos`)
- **Drift schema v3 → v4** (`make-migrations`, step tests):
  - `products`: add `image_id TEXT NULL` and `image_sha256 TEXT NULL`.
  - New table `product_images`: `id PK`, `product_id`, `local_path`, `thumb_path`, `sha256`, `bytes`, `state` (`local` | `uploading` | `uploaded` | `remote` | `failed`), `attempts`, `next_attempt_at`, `last_error`, `created_at`, `last_used_at` (for LRU). This is the upload queue and also the local cache index. Windows-friendly: no `sqflite` or `cached_network_image` dependency, because `flutter_cache_manager` needs sqflite, which does not run on Windows desktop.
- **Picking:**
  - `file_picker` with `FileType.image` on all platforms (already present).
  - Optionally add `image_picker` for the camera on Android and iOS. That needs `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in `ios/Runner/Info.plist`; `mobile_scanner` already requests the camera permission.
- **Processing.** Add the pure-Dart `image` package. In `Isolate.run`: decode, apply orientation, resize to a longest side of 800, encode JPEG 80, and make a 200 px thumbnail. Write both under `getApplicationSupportDirectory()/product_images/<id>.jpg` and `<id>_t.jpg` via a temporary file and rename.
- **Saving** (`ProductEditor.save`): in the **same** Drift transaction, set `products.image_id` and insert the `product_images` row in state `local`. The UI shows the image immediately from the local file. Removing the image sets `image_id = null` and enqueues a remote delete.
- **Uploader** (`data/sync/image_sync.dart`, called from `SyncEngine.syncOnce` **after** the push loop and before the pull):
  - Process due `local` rows, 2 at a time, with a dio multipart `PUT`.
  - On `409 product_missing`, retry later. On `4xx` validation errors, mark `failed` and show it in the status bar or on the card. Use the same backoff as the outbox.
  - An upload failure must never stop the push or the pull.
- **Downloader:**
  - After the pull, for products whose `image_id` has no local file, enqueue a thumbnail download first and a full image on demand (when the card is opened).
  - Store under the same directory. Run as a low-priority background task with an LRU cap of about 200 MB, evicting by `last_used_at`.
  - Offline, the kassa shows the cached file or a placeholder icon (`Icons.inventory_2_outlined`, as today). The UI never waits on the network.
- **UI** (rule 7: only `packages/ui` components):
  - Add a `PosThumbnail` component (size tokens 40/56/120 dp, rounded corners, placeholder, `Image.file` with `cacheWidth`) with golden tests and a Widgetbook entry.
  - Product card: an image slot at the top. Tap to add, replace or remove (all targets at least 48 dp). Show an "Internetga yuklanmagan" (not uploaded yet) badge while the state is `local` or `failed`.
  - Product list: a 40 dp thumbnail in the first table column and in the phone cards.
  - POS search results (`product_panel.dart` `PosListTile.leading`) and quick buttons: the thumbnail replaces the icon when available.
  - Add l10n strings (uz, uz-Cyrl, ru): `productImage`, `productImageAdd`, `productImageReplace`, `productImageRemove`, `productImageTooLarge`, `productImageUnsupported`, `productImageNotUploaded`.
- **Tests:**
  - The Drift migration v3 → v4.
  - `ProductEditor.save` writes `image_id` and the queue row atomically.
  - The uploader's backoff, `409` and duplicate handling with a mock dio.
  - The downloader skips files already present.
  - Golden tests for the list and the card with and without an image (phone 390×844, tablet 1024×768, desktop 1440×900).

### Suggested ROADMAP split
- T-A: backend model, endpoints, pull field and infra (media volume, backup, Caddy limit), plus tests.
- T-B: kassa Drift v4, processing, upload queue and download cache.
- T-C: UI (`PosThumbnail`, card, list, POS panel) with goldens and screenshots.

---

## Repro artifacts (scratchpad, not in repo)
- `scratchpad/repro/test_product_repro.py` and `conftest.py`. Run from `backend/` with:
  `PYTHONIOENCODING=utf-8 PYTHONPATH=. DJANGO_SETTINGS_MODULE=config.settings.test DATABASE_URL=postgres://pos:pos@127.0.0.1:55432/pos uv run pytest <scratch>/repro/test_product_repro.py -c pyproject.toml --rootdir . -s -q -p no:cacheprovider`
  - The only failing test is `test_name_nul_rejected`, which fails because the server returns 500 (that failure is the P0-2 bug). Every other test passed, which confirms the documented behaviour, including the lost sale, the 200-character and 20-barcode rejections, the deleted category, the stale overwrite and the blank PLU.
- `scratchpad/dart/main.dart`: `SearchKey` cases, run with `dart run main.dart`.
