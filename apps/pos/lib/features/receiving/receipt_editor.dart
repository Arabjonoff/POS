import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:pos_app/app/scanner/scanner_settings.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/barcode/barcode.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/receipts/receipt_store.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/products/product_card.dart';
import 'package:pos_app/features/receiving/supplier_picker.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

final StreamProviderFamily<ReceiptDoc?, String> receiptProvider = StreamProvider
    .autoDispose
    .family<ReceiptDoc?, String>(
      (ref, id) => ref.watch(receiptStoreProvider).watch(id),
    );

/// Kirim tahrirlovchisi (`stock-receipt.md`): skaner — qator yoki +1,
/// noma'lum kod — tovar kartasi (kod to'ldirilgan), qatorlarni tahrirlash,
/// tasdiqlash. Har o'zgarish darhol bazada (qoralama).
class ReceiptEditor extends ConsumerStatefulWidget {
  const ReceiptEditor({
    required this.receiptId,
    required this.onClose,
    super.key,
  });

  final String receiptId;
  final VoidCallback onClose;

  @override
  ConsumerState<ReceiptEditor> createState() => _ReceiptEditorState();
}

class _ReceiptEditorState extends ConsumerState<ReceiptEditor> {
  final _search = TextEditingController();
  final _note = TextEditingController();
  final _feedback = PosScanFeedbackController();
  bool _dialogOpen = false;
  bool _busy = false;
  bool _noteLoaded = false;

  ReceiptStore get _store => ref.read(receiptStoreProvider);

  @override
  void dispose() {
    _search.dispose();
    _note.dispose();
    _feedback.dispose();
    super.dispose();
  }

  Future<T?> _dialog<T>(Future<T?> Function() open) async {
    setState(() => _dialogOpen = true);
    try {
      return await open();
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _add(String productId, {int qtyMilli = 1000}) async {
    await _store.addProduct(widget.receiptId, productId, qtyMilli: qtyMilli);
    _feedback.flash(PosScanResult.success);
    unawaited(ref.read(scanSignalProvider).success());
  }

  Future<void> _onScan(ScanEvent event) async {
    if (_dialogOpen) return;
    final l10n = AppLocalizations.of(context);
    if (Barcodes.check(event.code) == BarcodeCheck.invalidCheckDigit) {
      _feedback.flash(PosScanResult.error);
      unawaited(ref.read(scanSignalProvider).notFound());
      showPosToast(
        context,
        message: l10n.scanInvalidCode,
        tone: PosTone.warning,
      );
      return;
    }
    final catalog =
        ref.read(productCatalogProvider).value ?? ProductCatalog(const []);
    final match = catalog.byCode(event.code);
    if (match != null) {
      await _add(match.product.id, qtyMilli: match.qtyMilli ?? 1000);
      return;
    }
    // Noma'lum kod — yangi tovar kartasi, saqlangach kirimga qo'shiladi.
    unawaited(ref.read(scanSignalProvider).notFound());
    final id = await _dialog(
      () => showProductCard(context, barcode: event.code),
    );
    if (id != null && mounted) await _add(id);
  }

  void _onTyping(String text) {
    final value = _search.text + text;
    _search.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  Future<void> _supplier(ReceiptDoc doc) async {
    final choice = await _dialog(
      () => showSupplierPicker(context, selectedId: doc.supplierId),
    );
    if (choice != null) {
      await _store.setSupplier(widget.receiptId, choice.supplierId);
    }
  }

  Future<void> _post(ReceiptDoc doc) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (doc.lines.isEmpty) {
      showPosToast(
        context,
        message: l10n.receivingEmptyPost,
        tone: PosTone.warning,
      );
      return;
    }
    final session = ref.read(sessionProvider);
    final user = session.user;
    if (user == null) return;
    var by = DiscountPolicy.canApprove(user.role) ? user.id : null;
    by ??= await _dialog(
      () =>
          requestManagerApproval(context, reason: l10n.receivingNeedsApproval),
    );
    if (by == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _store.post(
        widget.receiptId,
        by: by,
        storeId: session.device?.storeId,
      );
      if (!mounted) return;
      showPosToast(
        context,
        message: l10n.receivingPostedToast,
        tone: PosTone.success,
      );
      widget.onClose();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteDraft() async {
    await _store.deleteDraft(widget.receiptId);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final doc = ref.watch(receiptProvider(widget.receiptId)).value;
    if (doc == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_noteLoaded) {
      _note.text = doc.note;
      _noteLoaded = true;
    }
    final draft = doc.isDraft;
    final catalog =
        ref.watch(productCatalogProvider).value ?? ProductCatalog(const []);
    final results = _search.text.trim().isEmpty
        ? const <CatalogProduct>[]
        : catalog.search(_search.text).take(8).toList();

    return ScanListener(
      enabled: draft && !_dialogOpen,
      onScan: (e) => unawaited(_onScan(e)),
      onTyping: _onTyping,
      child: PosScanFeedback(
        controller: _feedback,
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PosIconButton(
                    key: const ValueKey('receipt-back'),
                    icon: Icons.arrow_back,
                    tooltip: l10n.receivingBack,
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: PosSpacing.s),
                  Expanded(
                    child: Text(
                      l10n.receivingTitle(
                        fmt.dateTime(doc.postedAt ?? doc.createdAt),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (compact ? PosTypography.h3 : PosTypography.h2)
                          .copyWith(color: p.text),
                    ),
                  ),
                  PosBadge(
                    label: draft
                        ? l10n.receivingDraft
                        : l10n.receivingPostedBadge,
                    tone: draft ? PosTone.warning : PosTone.success,
                  ),
                ],
              ),
              const SizedBox(height: PosSpacing.m),
              Wrap(
                spacing: PosSpacing.s,
                runSpacing: PosSpacing.s,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PosButton(
                    key: const ValueKey('receipt-supplier'),
                    label: doc.supplierName ?? l10n.receivingNoSupplier,
                    icon: Icons.local_shipping_outlined,
                    size: PosButtonSize.s,
                    variant: PosButtonVariant.secondary,
                    onPressed: draft ? () => unawaited(_supplier(doc)) : null,
                  ),
                  if (draft)
                    SizedBox(
                      width: compact ? double.infinity : 320,
                      child: PosTextField(
                        key: const ValueKey('receipt-note'),
                        controller: _note,
                        hint: l10n.receivingNote,
                        onChanged: (v) =>
                            unawaited(_store.setNote(widget.receiptId, v)),
                      ),
                    )
                  else if (doc.note.isNotEmpty)
                    Text(
                      doc.note,
                      style: PosTypography.body.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                ],
              ),
              if (draft) ...[
                const SizedBox(height: PosSpacing.m),
                PosSearchField(
                  key: const ValueKey('receipt-search'),
                  controller: _search,
                  hint: l10n.receivingSearchHint,
                  clearTooltip: l10n.actionClear,
                  onChanged: (_) => setState(() {}),
                ),
                for (final product in results)
                  PosListTile(
                    title: product.name,
                    subtitle: product.barcodes.isEmpty
                        ? null
                        : product.barcodes.first,
                    trailing: const Icon(Icons.add),
                    onTap: () async {
                      _search.clear();
                      setState(() {});
                      await _add(product.id);
                    },
                  ),
              ],
              const SizedBox(height: PosSpacing.m),
              Expanded(
                child: doc.lines.isEmpty
                    ? PosEmptyState(
                        icon: Icons.qr_code_scanner,
                        title: l10n.receivingEmptyLines,
                      )
                    : ListView.separated(
                        itemCount: doc.lines.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: PosSpacing.s),
                        itemBuilder: (context, i) => _LineRow(
                          key: ValueKey(doc.lines[i].id),
                          line: doc.lines[i],
                          editable: draft,
                          compact: compact,
                        ),
                      ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: PosSpacing.m),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: PosSpacing.m,
                    runSpacing: PosSpacing.s,
                    children: [
                      Text(
                        '${l10n.receivingLines(doc.lines.length)} · '
                        '${l10n.receivingTotal(fmt.money(doc.totalCostTiyin))}',
                        key: const ValueKey('receipt-total'),
                        style: PosTypography.bodyStrong.copyWith(color: p.text),
                      ),
                      if (draft)
                        Wrap(
                          spacing: PosSpacing.s,
                          children: [
                            PosButton(
                              key: const ValueKey('receipt-delete'),
                              label: l10n.receivingDelete,
                              variant: PosButtonVariant.ghost,
                              onPressed: _busy
                                  ? null
                                  : () => unawaited(_deleteDraft()),
                            ),
                            PosButton(
                              key: const ValueKey('receipt-post'),
                              label: l10n.receivingPost,
                              icon: Icons.check,
                              loading: _busy,
                              onPressed: _busy
                                  ? null
                                  : () => unawaited(_post(doc)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kirim qatori: miqdor, tannarx, sotish narxi (qoralamada tahrirlanadi).
class _LineRow extends ConsumerStatefulWidget {
  const _LineRow({
    required this.line,
    required this.editable,
    required this.compact,
    super.key,
  });

  final ReceiptLine line;
  final bool editable;
  final bool compact;

  @override
  ConsumerState<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends ConsumerState<_LineRow> {
  late final _qty = TextEditingController(text: _qtyText(widget.line));
  late final _cost = TextEditingController(
    text: formatMoneyInput(widget.line.costTiyin),
  );
  late final _sell = TextEditingController(
    text: formatMoneyInput(widget.line.sellTiyin),
  );
  bool _badQty = false;

  static String _qtyText(ReceiptLine l) =>
      formatQtyInput(l.qtyMilli, fractional: l.unit.fractional);

  @override
  void didUpdateWidget(_LineRow old) {
    super.didUpdateWidget(old);
    // Skan +1 — miqdor tashqaridan o'zgardi.
    final parsed = parseQtyMilli(
      _qty.text,
      fractional: widget.line.unit.fractional,
    );
    if (widget.line.qtyMilli != old.line.qtyMilli &&
        parsed != widget.line.qtyMilli) {
      _qty.text = _qtyText(widget.line);
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    _sell.dispose();
    super.dispose();
  }

  ReceiptStore get _store => ref.read(receiptStoreProvider);

  void _onQty(String text) {
    final qty = parseQtyMilli(text, fractional: widget.line.unit.fractional);
    final ok = qty != null && qty > 0;
    setState(() => _badQty = !ok);
    if (ok) unawaited(_store.setQty(widget.line.id, qty));
  }

  void _onCost(String text) {
    final cost = parseMoneyTiyin(text);
    if (cost != null) unawaited(_store.setCost(widget.line.id, cost));
  }

  void _onSell(String text) {
    final sell = parseMoneyTiyin(text);
    if (sell != null && sell > 0) {
      unawaited(_store.setSellPrice(widget.line.id, sell));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final line = widget.line;
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]'))];

    Widget field(
      String key,
      TextEditingController controller,
      String label,
      ValueChanged<String> onChanged, {
      String? error,
    }) => PosTextField(
      key: ValueKey('$key-${line.id}'),
      controller: controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: digits,
      textAlign: TextAlign.right,
      errorText: error,
      onChanged: onChanged,
    );

    final header = Row(
      children: [
        Expanded(
          child: Text(
            line.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.bodyStrong.copyWith(color: p.text),
          ),
        ),
        PosMoneyText(
          amount: line.totalTiyin,
          currency: fmt.currency,
        ),
        if (widget.editable)
          PosIconButton(
            key: ValueKey('remove-${line.id}'),
            icon: Icons.delete_outline,
            tooltip: l10n.receivingRemoveLine,
            onPressed: () => unawaited(_store.removeLine(line.id)),
          ),
      ],
    );

    final Widget values;
    if (widget.editable) {
      final fields = [
        field(
          'qty',
          _qty,
          '${l10n.receivingQty}, ${line.unit.label(l10n)}',
          _onQty,
          error: _badQty ? l10n.productErrQty : null,
        ),
        field('cost', _cost, l10n.receivingCost, _onCost),
        field('sell', _sell, l10n.receivingSell, _onSell),
      ];
      values = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, f) in fields.indexed) ...[
            if (i > 0) const SizedBox(width: PosSpacing.s),
            Expanded(child: f),
          ],
        ],
      );
    } else {
      values = Text(
        '${fmt.qty(line.qtyMilli, line.unit)} × ${fmt.money(line.costTiyin)} · '
        '${l10n.receivingSell}: ${fmt.money(line.sellTiyin)}',
        style: PosTypography.small.copyWith(color: p.textSecondary),
      );
    }

    return PosCard(
      padding: const EdgeInsets.all(PosSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: PosSpacing.s),
          values,
          if (line.sellBelowCost)
            Padding(
              padding: const EdgeInsets.only(top: PosSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PosBadge(
                  key: ValueKey('below-${line.id}'),
                  label: l10n.receivingSellBelowCost,
                  tone: PosTone.warning,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
