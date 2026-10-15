# Audit: printers and receipt (chek) printing — apps/pos

Date: 2026-10-15 · Scope: `apps/pos/lib/features/printing/*`, `apps/pos/lib/features/settings/*`,
store info (`backend/apps/tenants`, sync pull), tests in `apps/pos/test/printing/*`.
Read-only audit; nothing in the repo was changed. A throwaway probe script (copies of `wrap`/`_pair`/`plain`)
was run from the scratchpad to check the edge cases.

Note: `apps/pos/lib/data/receipts/receipt_store.dart` is about **goods receipts (kirim / stock receipt)**,
not sales receipts. It has nothing to do with printing.

---

## 1. Current state

### 1.1 Files
| File | Role |
|---|---|
| `features/printing/receipt.dart` (371 lines) | `ReceiptData`/`ReceiptLine`/`ReceiptPayment` model, `PaperWidth` (32/48), `ReceiptRow` (text, bold, center, barcode), `ReceiptBuilder.build()` (sale), `.buildShift()` (X/Z), `.render()` (plain-text preview, **used only in tests**), `.plain()`, `.wrap()`, `_pair()` |
| `features/printing/receipt_loader.dart` | Reads sale + items + payments + shift → `stores` row + cashier + unit codes + debt customer → `ReceiptData` |
| `features/printing/escpos.dart` | `EscPos.receipt(rows, encoding, cut, drawer)` → bytes: `ESC @`, `ESC t 17` (CP866) or nothing (UTF-8), `ESC a`, `ESC E`, CODE128 `GS k 73`, `ESC d 4`+`GS V 66 0`, drawer `ESC p 0 25 250`. Own CP866 encoder. |
| `features/printing/printer_transport.dart` | `NetworkPrinterTransport` (`IP[:port]`, default 9100, 5 s timeout), `WindowsSpoolerTransport` |
| `features/printing/winspool.dart` | Own FFI bindings to `winspool.drv` (EnumPrintersW level 4, RAW doc) |
| `features/printing/printer_settings.dart` | `PrinterSettings` + `PrinterSettingsController` (AsyncNotifier) |
| `features/printing/printer_service.dart` | `printSale`, `reprintLast`, `printTest`, `printShiftReport`, `openDrawer`, `PrinterHealth` (status bar) |
| `features/printing/printer_settings_panel.dart` | Settings → "Chek printeri" card |
| `features/settings/settings_screen.dart` | Settings page (language, auto-lock, scanner, printer, about) |
| Call sites | `features/pos/pos_screen.dart:344-372` (auto print, retry, "Oxirgi chek"), `features/shift/shift_screen.dart:49-53` (X/Z) |

### 1.2 Settings that exist today and where they live
**Per device — `local_settings` drift table (SQLite), key `printer`, JSON** (`printer_settings.dart:27-71`).
They survive restarts. They are not synced to the server.
- `connection`: none / network / windows
- `address`: `IP[:port]` or the Windows printer name
- `width`: 58 or 80 (→ 32 or 48 chars)
- `encoding`: cp866 / utf8
- `auto_print` (default true)
- `copies` 1–3
- `open_drawer` (default false)

**Per store — server `Store` model** (`backend/apps/tenants/models.py:45-58`): `name`, `address`, `phone` (stored normalised as `+998XXXXXXXXX`), `receipt_header`, `receipt_footer`.
- Synced down by pull (`backend/apps/sync/pull.py:30-33` → `apps/pos/lib/data/sync/pull.dart:101-113`) into the drift `Stores` table (`data/db/tables/reference_tables.dart:8-18`).
- They are read-only in the POS.
- **The only place to edit them is Django `/admin/`** (`backend/apps/tenants/admin.py:6-9`, StoreInline). That is the platform-admin UI. The shop owner has no UI: `apps/admin` is the platform admin (tenants/plans/payments), there is no store-settings endpoint, and the POS has no editor.
- **These fields do not exist anywhere:** tax ID (STIR/INN/JShShIR), legal name, logo, show/hide toggles.

### 1.3 Receipt layout builder (sale → lines → bytes)
`ReceiptLoader.load(saleId)` → `ReceiptData` → `ReceiptBuilder(l10n, width).build(data, copy:)` → `List<ReceiptRow>` → `EscPos.receipt(rows, encoding:, drawer:)` → `Uint8List` → `PrinterTransport.send`.
It is a pure function with snapshot tests (`test/printing/receipts/*.txt`: cash_58, cash_58_ru, cash_80, debt_58, mixed_58, shift_x_58, shift_z_58) and an "every row fits" test, which covers only the `cash` fixture.

What is printed today (`receipt.dart:164-222`):
- **Store block:**
  - store name (bold, centered, wrapped)
  - address, phone, header lines (centered, blank ones skipped)
  - "NUSXA" on reprints
- **Sale info:** `Chek: D3-000123` + date/time on one row (Tashkent TZ), `Kassir: <name>`
- **Per item:**
  - the name wraps by word, and "qty x price" goes right-aligned on its last line, or on its own line if it doesn't fit
  - an optional `  Chegirma -X` line
  - the line total right-aligned on its own row
- **Totals:** sale-level `Chegirma`, **`JAMI`** (bold only, not enlarged)
- **Payments:** one row per payment (cash shows the *received* amount), `Qaytim`
- **Debt customer:** name + "Joriy qarz"
- **Footer:**
  - CODE128 barcode of the sale number
  - footer text, or the default "Xaridingiz uchun rahmat!"
  - "Fiskal chek emas"

Widths: `PaperWidth.mm58(32)`, `mm80(48)` (Font A). No 42-column option (512-dot 80 mm printers) and no Font B.

### 1.4 Encoding and code pages
- `ReceiptBuilder.plain()` (`receipt.dart:319-322`) is applied to every text row. It maps:
  - NBSP / U+202F / U+2007 → space
  - U+2212 / en dash / em dash → `-`
  - **U+02BB ʻ, U+02BC ʼ, U+2018, U+2019 and backtick → ASCII `'`**
  - So Uzbek Latin oʻ/gʻ prints correctly as `o'`/`g'` in both modes. Good.
- CP866 (`escpos.dart:88-117`):
  - ASCII is passed through, А–я and Ё/ё/№ are mapped.
  - Uzbek Cyrillic is folded: Ў→У, ў→у, Қ→К, Ғ→Г, Ҳ→Х (bug for Ў/ў, see B1).
  - Everything else → `?`.
- UTF-8: the raw `utf8.encode` is sent and **no command is sent to put the printer into UTF-8 mode** (see B5).
- **Not sent: `FS .` (cancel Chinese/Kanji mode)** (see B4).

### 1.5 Transports and printer selection
- Network (IP:9100) on every platform.
- Windows spooler RAW (installed printers list, selectable as radio tiles).
- Android Bluetooth/USB: **not implemented** (T-047 open, Q-007 open).
- No network discovery.
- Health check:
  - network: a TCP connect
  - Windows: only checks that the printer *name exists*

### 1.6 Test print, preview, logo
- **Test print: exists** (`printer_service.dart:83-98`). Title, ruler `1234567890…` to the full width, date/time, a Latin/Cyrillic sample, "if this reads correctly the printer is ready". It does **not** print the store header/footer or a sample sale, so the owner can't see what a real receipt will look like.
- "Pul qutisini ochish" button: exists.
- **Preview: none.** `ReceiptBuilder.render()` (`receipt.dart:307-316`) is a text renderer used only by the snapshot tests. No widget.
- **Logo: none.**
  - No image field on the server or locally.
  - No raster (`GS v 0` / `ESC *`) encoder.
  - `file_picker` is already a dependency (`apps/pos/pubspec.yaml:19`). There is no `image` package, but decoding can be done with `dart:ui`.
- packages/ui has **no monospace font/typography token**. Only Inter is bundled.

### 1.7 Refunds, shift reports, debt payments
- **Refund receipt: not printed at all.** There are no print calls in `features/refunds`. The `Refunds` table has no number of its own, only `saleId`, `method`, `totalTiyin`, `reason`, `at`.
- **Debt payment (qarz to'lovi) receipt: not printed.**
- **X/Z shift report: printed** (`buildShift`, `printShiftReport`) with:
  - store name
  - opened / closed (or printed) time, cashier
  - sales by payment type, refunds, cash in/out, debt payments
  - expected / counted / difference
  - "Fiskal chek emas"

  Bug B2 applies here (`·` prints as `?`).

---

## 2. Bugs

Severity: H = visible on every or many receipts or loses money/info, M = visible in common cases, L = edge case or cosmetic.

**B1 (M) — Ў/ў are folded to У/у although CP866 has them.**
- **Where:** `escpos.dart:95-97`.
- **Cause:** IBM CP866 has Ў at 0xF6 and ў at 0xF7. The map sends them to У/у.
- **Impact:** "Ўзбекистон", "сўм", "тўғри" lose the ў on every uz-Cyrl receipt. Only Қ Ғ Ҳ really need folding.
- **Fix:** map 0x040E→0xF6 and 0x045E→0xF7 directly in `_cp866`; keep folding Қ Ғ Ҳ only. Also map ° (U+00B0)→0xF8, · (U+00B7)→0xFA, ∙ (U+2219)→0xF9, NBSP→0xFF, Є/є/Ї/ї→F2–F5.
- **Test:** update the expectation in `escpos_test.dart` "CP866: latin as is, russian and uzbek cyrillic". This is a correction, not a weakening. Also add a hardware checklist item: the test print must show Ў.

**B2 (M) — The shift report prints `?` instead of `·`.**
- **Where:** `receipt.dart:266, 273` builds `'${l10n.reportSales} · …'`. `plain()` (`:319-322`) doesn't touch U+00B7, and `_cp866` (`escpos.dart:111-116`) maps it to `0x3F '?'`.
- **Impact:** every X/Z report on paper reads "Savdolar ? 42 ta chek" and "Qaytarishlar ? 1 ta chek". The snapshot files don't catch it because they are UTF-8 text.
- **Fix:** B1's mapping (0xFA), or map `·` → `-` in `plain()`.
- **Test:** encode `buildShift` rows with cp866 and assert no `0x3F` bytes appear unless the source text had `?`. This is a generic "no unknown glyphs" test for all snapshot fixtures × 3 locales.

**B3 (M) — `plain()` misses common typographic characters.**
- **Where:** `receipt.dart:319-322`.
- **Cause:** product, store and customer names come from users and often contain “ ” „ « » … × ½ № é ü ö ı ş and emoji. In CP866 all of these except № become `?`.
- **Impact:** "Sok «Bliss» 1L" prints as "Sok ?Bliss? 1L".
- **Fix:** a transliteration table in `plain()`:
  - quotes (“ ” „ « ») → `"`
  - `…` → `...`
  - `×` → `x`
  - accented Latin → base letter (a small explicit table; Dart has no NFD)
  - emoji and other symbols → dropped
- **Test:** table-driven unit test.

**B4 (H on Chinese-firmware printers) — `FS .` (cancel Kanji/Chinese mode) is never sent.**
- **Where:** `escpos.dart:61-62`.
- **Cause:** many Xprinter, Rongta and HPRT 58/80 mm printers (common in Uzbekistan, see Q-007) ship with Chinese double-byte mode on. Bytes ≥0x80 are then read as GB18030 pairs.
- **Impact:** every Cyrillic (ru/uz-Cyrl) receipt comes out as Chinese characters, and column alignment breaks.
- **Fix:** send `[0x1C, 0x2E]` right after `ESC @` (Epson ignores it). Make the code page number configurable (default 17 = PC866). Some firmware uses a different index, so add an advanced field "kod sahifasi raqami".
- **Test:** `escpos_test` "receipt: init, code page…" expects `1B 40 1C 2E 1B 74 11`.

**B5 (M) — "UTF-8" mode is mostly a trap.**
- **Where:** `escpos.dart:62, 90`; settings `printer_settings_panel.dart:167-175`.
- **Cause:** nothing switches the printer into UTF-8. Epson TM-T88VI+ needs `FS ( C 02 00 30 02`, and most cheap printers don't support UTF-8 at all.
- **Impact:** in CP437 each Cyrillic letter becomes 2 glyphs. A 32-char row becomes about 50 printed chars, the printer hard-wraps, and the whole layout falls apart. A user who picks UTF-8 to get ў/қ/ғ/ҳ gets garbage.
- **Fix:**
  - send `FS ( C` when in UTF-8 mode
  - relabel it "UTF-8 (faqat qo'llaydigan printerlar)"
  - add a third mode, **"Grafik (rasm)"**: the same line model rendered to a 1-bit bitmap with a bundled monospace font and sent with `GS v 0`. This is the only way to print қ ғ ҳ and any Unicode correctly. See §3.4. Recommended for uz-Cyrl shops.

**B6 (L) — Width is measured in UTF-16 code units.**
- **Where:** `receipt.dart:330-342, 346-370` (`.length`, `substring`).
- **Cause:** an emoji (surrogate pair) counts as 2 but prints as 1 `?` (the CP866 encoder iterates runes). A combining mark (o + U+0306) counts as 1 but becomes `o?` in CP866. `substring` can also split a surrogate pair.
- **Impact:** the right column shifts by 1 to 2 characters. The probe showed `|Ŏzbek 🍎 sok          1 x 5 000|`.
- **Fix:** after B3 normalisation everything is a BMP single code unit. Assert it, or measure with `runes.length` and cut on runes.
- **Test:** a fuzz test that every row of the *encoded* output is ≤ chars.

**B7 (L) — `_pair` never truncates or wraps the right column.**
- **Where:** `receipt.dart:330, 342` (`right.padLeft(_w)` with `right.length > _w`).
- **Impact:** an over-long "qty x price" overflows the paper. The probe showed `1 000 000 dona x 1 234 567 890` = 30/32 at 58 mm. Russian `шт` or longer unit names, prices with tiyin (`,50`) and 7-digit quantities can reach 33 or more. Rare, but then the printer auto-wraps and the next total ends up under the wrong item.
- **Fix:** if `right.length > _w`, put "qty x" and "price" on separate right-aligned rows.
- **Test:** add to "every row fits the paper" a fixture with these lines, at 32/42/48:
  - qty 12 345,678 kg
  - price 12 345 678,50
  - a 60-char name with ʻ
  - a 40-char unbreakable word
  - a long cashier name

  The current test (`receipt_test.dart:162-169`) only checks the `cash` fixture.

**B8 (L) — An empty store name prints an empty bold line.**
- **Where:** `receipt.dart:165`.
- **Cause:** `wrap('')` returns `['']`. `buildShift` guards this (`:251`), `build` does not. It happens when the shift/store row is missing (`receipt_loader.dart:150-154, 182`).
- **Fix:** `if (name.isNotEmpty)`.

**B9 (L) — "Kassir: " is printed with an empty name.**
- **Where:** `receipt.dart:176`.
- **Fix:** guard it.

**B10 (L) — The unit is hidden for g/pack/l-type units.**
- **Where:** `receipt.dart:181-183`.
- **Cause:** the unit is shown only if `unit.fractional || qty%1000 != 0`.
- **Impact:** 250 g of tea at a per-gram price prints `250 x 100`, and 3 packs print `3 x …`, which is ambiguous.
- **Fix:** show the unit for every unit except `pcs`.
- **Test:** snapshot.

**B11 (M, presentation) — No subtotal line before the sale discount, and no discount summary.**
- **Where:** `receipt.dart:192-195`.
- **Impact:** with a sale-level discount the receipt shows the item totals and then `Chegirma -1 500`, `JAMI 35 000`, with no "Summa 36 500" line. Line discounts don't show the percent. The customer can't easily check the math.
- **Fix:**
  - if any discount: `Summa (chegirmasiz)`, then `Chegirma` (line + sale combined, or both), then `JAMI`
  - optionally `-10%` next to a line discount (`Cart` has `Discount` with percent, but it is not persisted; check `sale_items` before promising this)

**B12 (M) — Mixed payment prints received cash as the payment amount.**
- **Where:** `receipt.dart:197-203` uses `p.receivedTiyin ?? p.amountTiyin` for cash.
- **Example:** in `mixed_58.txt`, JAMI is 106 950. The receipt shows Naqd 30 000 + Karta 50 000 + Nasiya 30 000 = 110 000, then Qaytim 3 050. The payment lines don't add up to JAMI, and the owner asked for "payment method, **paid amount** and change".
- **Fix:** print the cash *applied* (`amountTiyin` = 26 950). When `received > amount`, add a `Berildi (naqd) 30 000` row and keep `Qaytim 3 050`. Optionally add a `To'landi` total. All the data is already in `sale_payments` (`received_tiyin`, `change_tiyin`).
- **Test:** update the `mixed_58`/`cash_58` snapshots. This is a deliberate format change; record it in printing.md.

**B13 (M) — Retrying after a failed first print reprints as "NUSXA".**
- **Where:** `pos_screen.dart:361-363` calls `_printReceipt(saleId, copy: true)` as the retry.
- **Impact:** if the printer was off at checkout, the customer's *original* receipt comes out labelled NUSXA. The `copies` setting is ignored and the cash drawer is not opened.
- **Fix:** retry with `copy: false`. Mark the sale as printed, for example in a local `printed_at` setting or table, so that later reprints are copies.

**B14 (M) — The cash drawer only opens through receipt printing.**
- **Where:** `pos_screen.dart:344-347` (only when `autoPrint`), `printer_service.dart:50-53`.
- **Impact:** with "Savdodan keyin chekni chiqarish" off and "Naqd to'lovda pul qutisini ochish" on, the drawer never opens for cash sales.
- **Fix:** if `!autoPrint && openDrawer && cash`, send `EscPos.drawerOnly()`.
- **Test:** widget test with a fake transport.

**B15 (L/M) — "Joriy qarz" is the debt at *print* time, not after this sale.**
- **Where:** `receipt_loader.dart:170-174, 212-213` (`CustomerDirectory.byId(...).balanceTiyin`).
- **Impact:** a reprint days later, or after another debt sale, shows a different number than the original. The spec says "savdodan keyingi qarzi".
- **Fix:** compute the balance as of the sale's debt entry (sum of entries with `at <= sale.soldAt`), or label it "Qarz (chop etilgan paytda)".
- **Test:** loader test with a later debt entry.

**B16 (L) — The printer address is saved and probed on every keystroke.**
- **Where:** `printer_settings_panel.dart:147-148` and `printer_service.dart:172-181`.
- **Cause:** each change rebuilds `PrinterHealth`, which opens a socket to a partial IP with a 5 s timeout.
- **Impact:** the status flickers, sockets are wasted, and the DB is written on every key.
- **Fix:** debounce 500 ms, or save on submit/blur.

**B17 (L) — The Windows health check is too optimistic.**
- **Where:** `printer_transport.dart:278-279` checks the name only. `WritePrinter` succeeds into the queue even when the printer is off or out of paper.
- **Impact:** a "printed" toast is shown but nothing comes out.
- **Fix (partial):** `GetPrinterW` level 2 `Status`/`Attributes & WORK_OFFLINE`. Document the limitation.

**B18 (M, gap) — No refund receipt and no debt-payment receipt.**
- **Where:** `features/refunds/*`, `features/customers/*`.
- **Fix:** see §3.6.

**B19 (H, gap for this feature) — The owner cannot edit store receipt info, and there is no tax ID or logo.**
- **Where:** `backend/apps/tenants/admin.py:6-9` is the only editor.
- **Fix:** see §3.1.

**B20 (L) — The store phone prints raw.**
- **Where:** server normalised `+998712000000` (`backend/apps/core/phone.py:9`), printed as-is (`receipt.dart:168`). The snapshot fixture uses a pre-spaced phone, so the tests hide it.
- **Fix:** format as `+998 71 200 00 00` in the builder (pure helper with a test).

Other observations (not bugs):
- `JAMI` is only bold. A professional receipt uses double height (`GS ! 0x01`), which doesn't change the chars per line.
- Every item takes 2 rows even for "1 x 4 000 / 4 000". An optional compact mode (one row when qty=1 pcs and there is no discount) saves about 30% paper.
- Each copy is a separate network connection. Parallel jobs (auto print + "Oxirgi chek") can collide on single-connection printers. Consider a serial print queue in `PrinterService`.

Verified OK:
- Wrapping long names by word and hard-splitting long words (probe + `mixed_58`).
- Right alignment at 32/48 for amounts up to 12 345 678.
- Weighted qty `1,250 kg x 6 000` and `0,250 kg`.
- Line discount math (`SaleLineInput.totalTiyin = lineTotal - discount`, `receipt_loader` passes `sale.discountTiyin` = sale-level only, not double counted).
- Change = Σ `change_tiyin` (only cash has change).
- Date/time in Tashkent TZ.
- CODE128 sale number fits 384 dots (about 290 dots at module 2).

---

## 3. Implementation plan

### 3.0 Tasks (ROADMAP proposal)
1. **T-048a Chek: xatolarni tuzatish.** B1–B4, B8–B10, B12–B14, B16, B20, plus tests. Small and independent; do this first.
2. **T-048b Chek modeli + jonli ko'rinish.** Document model, layout toggles, preview widget, 42-column option.
3. **T-048c Do'kon rekvizitlari.** Server fields + sync + POS editor (owner/manager).
4. **T-048d Logotip.** Pick → raster → `GS v 0`, preview.
5. **T-048e Qaytarish va qarz to'lovi cheki.** Graphic (raster) print mode.

Each task updates `docs/specs/printing.md`. New decision: `docs/decisions/00NN-receipt-settings.md`, which records what is per store vs per device and why, how the logo is stored, and the raster mode.

### 3.1 Settings model

**A. Store-level "Chek rekvizitlari" (one per store, identical on every till, server-authoritative, synced).**
Add to `Store` (Django). All fields are additive with blank defaults, so old POS clients ignore them (`pull.dart` reads named keys only). That satisfies rule 10.

| field | type | default | note |
|---|---|---|---|
| name | exists | — | |
| address, phone, receipt_header, receipt_footer | exist | '' | |
| `legal_name` | Char(200) | '' | "YaTT Karimov A." / "\"Baraka\" MChJ"; printed only if set |
| `tin` | Char(14) | '' | STIR (9 digits) or JShShIR (14). Validator: digits, length 9 or 14. **Printed only if non-empty, never derived or guessed.** Label "STIR" vs "JShShIR" by length. |
| `receipt_logo` | Text | '' | base64 PNG, already reduced: 1-bit or grayscale, ≤ 576 px wide, ≤ 240 px tall, ≤ 48 KB (validated server-side) |
| `receipt_options` | JSON | `{}` | display toggles: `show_logo`, `show_address`, `show_phone`, `show_tin`, `show_legal_name`, `show_cashier` (true), `show_barcode` (true), `show_customer_debt` (true), `compact_items` (false), `show_subtotal` (true). Unknown keys are ignored, missing keys use defaults, so the set can grow without migrations. |

- Pull: extend `SyncStoreSerializer.fields`.
- POS:
  - drift `Stores` gets columns `legalName`, `tin`, `receiptLogo`, `receiptOptions` with defaults (schema bump + `steps` migration + schema test)
  - `pull.dart` case 'store'
- Editing from the POS (the owner has no other UI): a new outbox event `store.upserted`, following the `product.upserted` precedent.
  - Handler in `backend/apps/sync/handlers.py`. Allowed roles: owner, manager.
  - Must have the mandatory tenant-isolation test (rule 4) and a role test.
  - Payload: the editable fields only. Validate `tin` and the logo size.
  - The local `stores` row is updated in the same SQLite transaction as the outbox insert (offline-first, rule 2). Push-before-pull in `SyncEngine.syncOnce` keeps the edit from being overwritten.
  - **Deploy the server before the POS release.** Old servers reject an unknown event type, which would leave it `rejected`.
- Optional later: the same fields in Django admin (`StoreInline.fields`).

**B. Device-level "Printer" (per till, `local_settings` key `printer`, already persisted).** Extend `PrinterSettings` (`fromJson` defaults keep old JSON working):

| key | default | note |
|---|---|---|
| connection, address, width, encoding, auto_print, copies, open_drawer | as today | |
| `chars` | null → width.chars | 32 / 42 / 48 override (80 mm printers with 512 dots = 42) |
| `encoding` | add `raster` | "Grafik (rasm)" mode, §3.4 |
| `code_page` | 17 | number sent with `ESC t n` for CP866 |
| `cancel_kanji` | true | sends `FS .` (B4) |
| `print_logo` | true | per device: logos are slow over Bluetooth |
| `cut` | true | some printers have no cutter |
| `feed_lines` | 4 | feed before the cut |
| `dots` | 384 (58) / 576 (80) | printable width for raster and logo |

Why the split: the store identity (name, TIN, logo, footer) must be the same on every till and survive a till being reinstalled. Hardware facts (port, paper, code page) differ per till.

### 3.2 One line model for printer and preview (single source of truth)
Replace `List<ReceiptRow>` with a small block document (pure Dart, `features/printing/receipt_doc.dart`):
```dart
sealed class ReceiptBlock {}
class TextBlock  extends ReceiptBlock { String text; Align align; bool bold; bool tall; }  // text already wrapped/padded to `chars`
class RuleBlock  extends ReceiptBlock { String char; }          // '-' or '='
class BarcodeBlock extends ReceiptBlock { String data; }       // CODE128
class ImageBlock extends ReceiptBlock { MonoBitmap bitmap; }   // logo, width ≤ dots
class FeedBlock  extends ReceiptBlock { int lines; }
class ReceiptDoc { int chars; int dots; List<ReceiptBlock> blocks; }
```
- `ReceiptBuilder.build(data, layout: ReceiptLayout)` → `ReceiptDoc`. `ReceiptLayout` = store options + device chars. All wrapping and padding happens here, once.
- `EscPos.encode(ReceiptDoc, PrinterProfile)` → bytes:
  - text: `ESC a`, `ESC E`, `GS ! 0x01` for `tall`
  - images: `GS v 0` in bands
  - barcode: `GS k`
  - CP866 or UTF-8 text, or the whole doc rasterised in `raster` mode
- `ReceiptPreview(doc)` widget renders **the same blocks**:
  - one `Text` per `TextBlock` with a monospace font, scaled so `chars` columns fill the paper width (`FittedBox` per row or a computed font size: `paperWidthPx / (chars * advance)`)
  - `ImageBlock` via `RawImage` from `MonoBitmap.toRgba()`
  - `BarcodeBlock` via a small `CustomPainter` that draws the real CODE128 module pattern (pure encoder shared with the test)
  - white "paper" token even in dark theme

  Because preview and printer consume the same `ReceiptDoc`, they cannot drift apart. In `raster` mode the preview can show the exact bitmap that will be sent.
- Rule 7: add a monospace font (e.g. JetBrains Mono or Roboto Mono; it must cover Latin Extended incl. ʻ and Cyrillic incl. ў қ ғ ҳ) and a `PosTypography.receipt` token plus a `receiptPaper` palette color in `packages/ui`. Optionally a generic `PosReceiptPaper` container component with a Widgetbook entry. The receipt-specific widget stays in apps/pos.
- Preview data: the last sale if one exists, otherwise a built-in sample `ReceiptData`. Sample product names and amounts must come from ARB keys (rule 6). Include a long Uzbek name with ʻ, a weighted item, a line discount, mixed payment and change, so the preview exercises every path.
- Settings UI: a new card "Chek ko'rinishi" (store, owner/manager only, PIN-gated like reports).
  - Fields: name, legal name, address, phone, STIR, header (multi-line), footer (multi-line), logo picker plus switches for each toggle.
  - Live preview on the right on tablet/desktop, below on phone. The 58/80 tab in the preview follows the device setting.
  - Saving is debounced; nothing is saved per keystroke (see B16).
  - The "Test chek" button sits next to the preview and prints the *preview document* plus a charset/ruler footer.
  - Printer selection stays in the existing "Chek printeri" card, with the new advanced fields (chars, code page, cut, feed, logo on/off) behind "Qo'shimcha".

### 3.3 Logo pipeline
1. Pick with `file_picker` (already a dependency), PNG or JPG.
2. Decode with `dart:ui` `instantiateImageCodec` and `toByteData(format: rawRgba)`. No new package.
3. Resize so width ≤ 576 px and height ≤ 240 px (box filter, keep aspect ratio).
4. Composite alpha on white, then luminance (integer math: `(299R+587G+114B)/1000`).
5. Store a grayscale PNG (or 8-bit gray bytes) as base64 in `Store.receipt_logo`.
6. Preview the threshold/dither result before saving. Offer "Kontrast" (threshold) and "Rasm" (Floyd–Steinberg dither) modes.
7. At print time, pure Dart `MonoBitmap.fromGray(gray, targetWidth: min(logoW, dots))`:
   - scale to the device's `dots` (384 / 576)
   - threshold or dither
   - pack 1 bpp MSB-first, row width rounded up to bytes
   - center by left-padding the bitmap to `dots`, or use `ESC a 1`
8. ESC/POS: `GS v 0 m=0 xL xH yL yH data`, split into bands of ≤ 128 rows (cheap printer buffers overflow on one big command), followed by `ESC @`-safe state. Height cap: 240 dots (about 30 mm).
9. Tests:
   - `MonoBitmap` on a known 16×8 pattern → exact bytes
   - band splitting
   - width clamp at 384/576
   - dithering determinism
   - `EscPos` output contains `1D 76 30 00` with the right xL/xH/yL/yH

### 3.4 Graphic (raster) print mode (fixes қ ғ ҳ and any Unicode)
- Render the `ReceiptDoc` text with the same monospace font into a `dart:ui` `PictureRecorder` canvas, `dots` wide, then threshold → `MonoBitmap` → `GS v 0` bands.
- It is slower (about 10–30 KB per receipt): fine over LAN or USB, acceptable over Bluetooth.
- Default stays CP866. Suggest raster when the app language is uz-Cyrl or when product names contain characters outside CP866.
- This needs `dart:ui`, so it runs on the main isolate (or a `RootIsolateToken` background isolate). Rendering is quick, so the receipt still goes out in the background without blocking the sale.

### 3.5 Receipt layout (target)
```
            [LOGO]
         Baraka market            (bold, tall)
    "Baraka" MChJ                 (legal_name, if set)
      Chilonzor 7, 12-uy          (if show_address & set)
     Tel: +998 71 200 00 00       (formatted, if set)
        STIR: 123456789           (only if tin set & show_tin)
   <header lines>
   NUSXA                          (reprint)
--------------------------------
Chek: D3-000123 13.10.2026 20:15
Kassir: Aziza                     (if set & show_cashier)
--------------------------------
Kungaboqar yog'i Oltin Saxovat 5
litr                  1 x 98 000
  Chegirma 10%            -9 800
                          88 200
Olma qizil     1,250 kg x 15 000
                          18 750
--------------------------------
Summa                    116 750  (only when any discount)
Chegirma                  -9 800
JAMI                     106 950  (bold, double height)
Naqd                      26 950
Karta                     50 000
Nasiya                    30 000
Berildi (naqd)            30 000
Qaytim                     3 050
--------------------------------
Mijoz: Olim aka
Qarz (savdodan keyin)     30 000
--------------------------------
      [CODE128 D3-000125]
   <footer / Xaridingiz uchun rahmat!>
        Fiskal chek emas
```
At 42 and 48 columns the same rules apply. Nothing is hard-coded to 32.

### 3.6 Refund and debt-payment receipts
- `ReceiptBuilder.buildRefund(RefundReceiptData)`:
  - title "QAYTARISH"
  - original sale number + date
  - refund time, cashier, approver
  - items (qty × price, total)
  - total refunded
  - method (Naqd qaytarildi / Qarzdan ayirildi)
  - reason
  - customer's debt after
- Loader from `refunds` + `refund_items` → `sale_items` (name snapshot, price).
- Print after a refund completes, if `autoPrint`, same background/failure UX. No drawer on a debt-method refund. Drawer on a cash refund only if `open_drawer`.
- `buildDebtPayment`: customer, amount, method, debt before and after.

### 3.7 Tests (what "green" means for these tasks)
- **Layout unit tests** (pure), for chars ∈ {32, 42, 48} and locale ∈ {uz, uz-Cyrl, ru}:
  - snapshots for cash, card, debt, mixed, discounts, weighted, refund, debt payment, shift X/Z
  - with and without logo, TIN and legal name
  - every toggle off
- **Fuzz/property test:** random names (Latin with ʻ ʼ ‘ ’, Cyrillic with ў қ ғ ҳ, quotes, emoji, 50-char words), amounts up to 99 999 999,99 and qty up to 99 999,999 kg. After `EscPos.encode`, every text line has ≤ chars glyphs, and with cp866 no `?` byte appears that wasn't `?` in the source.
- **EscPos tests:**
  - `FS .` + `ESC t n` order
  - B1 mappings, `·`, `°`
  - `GS !` tall
  - `GS v 0` bands
  - UTF-8 mode `FS ( C` command
- **Settings tests:**
  - JSON round trip
  - old JSON without the new keys → defaults
  - `tin` validation (9 or 14 digits)
  - logo size limit
- **Widget tests:**
  - receipt settings card persists to drift and creates a `store.upserted` outbox row in one transaction
  - preview updates live when a toggle flips
  - test print sends the preview doc to the fake transport
  - cashier role cannot open the store card
- **Golden tests:**
  - `ReceiptPreview` at 58/80, light and dark (paper stays white), with logo
  - settings screen at 390×844, 1024×768, 1440×900 → `docs/screenshots/T-048x/`
- **Backend tests:**
  - migration
  - `SyncStoreSerializer` includes the new fields
  - `store.upserted` applied for owner/manager, rejected for cashier
  - **other-tenant isolation**
  - tin/logo validation
- **Manual hardware checklist** in `docs/`: Xprinter 58/80 (Chinese mode), Epson TM-T20, Windows spooler, LAN. Print the test page with Ў ў Қ Ғ Ҳ and oʻ gʻ, the logo, a 48-column ruler, and the cut.

### 3.8 Questions for the owner (QUESTIONS.md)
- Which tax requisites should print, and what are they called: STIR (legal entity) and/or JShShIR (YaTT)? Should both be possible? (Business and legal; never filled in automatically.)
- Who may edit the receipt requisites: owner only, or the manager too?
- Is a single logo per store enough (vs. per till)?
- Should the default print mode for uz-Cyrl shops be graphic (correct қ ғ ҳ, slower) or CP866 (fast, folded letters)?
