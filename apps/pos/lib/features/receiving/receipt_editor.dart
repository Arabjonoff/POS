import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:pos_app/app/scanner/scanner_settings.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/shell/subscription_banner.dart';
import 'package:pos_app/app/sync/sales_gate.dart';
import 'package:pos_app/core/barcode/barcode.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/catalog/product_editor.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/receipts/receipt_store.dart';
import 'package:pos_app/data/sync/server_features.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/products/product_card.dart';
import 'package:pos_app/features/receiving/receipt_badges.dart';
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
    this.onOpen,
    super.key,
  });

  final String receiptId;
  final VoidCallback onClose;

  /// Boshqa kirimni ochish (tuzatish qoralamasi, yangi versiya).
  final ValueChanged<String>? onOpen;

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

  /// Chaqnash va signal — faqat skaner uchun (oddiy bosishda ekran chaqnamaydi).
  Future<void> _add(
    String productId, {
    int qtyMilli = 1000,
    bool scanned = false,
  }) async {
    await _store.addProduct(widget.receiptId, productId, qtyMilli: qtyMilli);
    if (!scanned) return;
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
      await _add(
        match.product.id,
        qtyMilli: match.qtyMilli ?? 1000,
        scanned: true,
      );
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
    if (doc.isCorrection) {
      await _postCorrection(doc);
      return;
    }
    final session = ref.read(sessionProvider);
    final by = await _approver(l10n.receivingNeedsApproval);
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

  /// Ega/menejer — o'zi; kassir — menejer PIN'i bilan.
  Future<String?> _approver(String reason) async {
    final user = ref.read(sessionProvider).user;
    if (user == null) return null;
    if (DiscountPolicy.canApprove(user.role)) return user.id;
    return _dialog(() => requestManagerApproval(context, reason: reason));
  }

  /// Qoralamani o'chirish — tasdiq bilan (audit UI-P1-1: tugma "Tasdiqlash"
  /// yonida, bitta bosishda butun kirim yo'qolardi).
  Future<void> _deleteDraft(ReceiptDoc doc) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (doc.lines.isNotEmpty || doc.isCorrection) {
      final ok = await _dialog(
        () => showPosConfirm(
          context: context,
          title: doc.isCorrection
              ? l10n.receivingDiscardCorrection
              : l10n.receivingDeleteDraftTitle,
          message: doc.isCorrection
              ? l10n.receivingDiscardCorrectionMessage
              : l10n.receivingDeleteDraftMessage,
          confirmLabel: doc.isCorrection
              ? l10n.receivingDiscardCorrection
              : l10n.receivingDelete,
          cancelLabel: l10n.actionKeep,
          icon: Icons.delete_outline,
          danger: true,
        ),
      );
      if (ok != true || !mounted) return;
    }
    await _store.deleteDraft(widget.receiptId);
    final original = doc.correctsId;
    if (original != null && widget.onOpen != null) {
      widget.onOpen!(original);
    } else {
      widget.onClose();
    }
  }

  // ---- Tahrirlash va bekor qilish (T-102) ---------------------------------

  Future<void> _edit(ReceiptDoc doc) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final draft = doc.correctionDraftId;
    if (draft != null) {
      widget.onOpen?.call(draft);
      return;
    }
    // Qoralama qoldiq va narxga ta'sir qilmaydi — ruxsat saqlashda so'raladi.
    try {
      final id = await _store.startCorrection(doc.id);
      if (mounted) widget.onOpen?.call(id);
    } on ReceiptNotEditableException {
      if (mounted) _toast(l10n.receivingNotEditable, PosTone.warning);
    }
  }

  Future<void> _cancel(ReceiptDoc doc) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final ok = await _dialog(
      () => showPosConfirm(
        context: context,
        title: l10n.receivingCancelTitle,
        message: l10n.receivingCancelMessage,
        confirmLabel: l10n.receivingCancelReceipt,
        cancelLabel: l10n.actionKeep,
        icon: Icons.undo,
        danger: true,
      ),
    );
    if (ok != true || !mounted) return;
    // Avval nima bo'lishini ko'rsatamiz, keyin ruxsat (kassir — menejer PIN).
    final by = await _approver(l10n.receivingEditNeedsApproval);
    if (by == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _store.cancel(
        doc.id,
        by: by,
        storeId: ref.read(sessionProvider).device?.storeId,
      );
      if (mounted) _toast(l10n.receivingCancelledToast, PosTone.success);
    } on ReceiptNotEditableException {
      if (mounted) _toast(l10n.receivingNotEditable, PosTone.warning);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _postCorrection(ReceiptDoc doc) async {
    final l10n = AppLocalizations.of(context);
    final originalId = doc.correctsId!;
    final original = await _store.load(originalId);
    if (original == null || !mounted) return;
    // Bazadan to'g'ridan-to'g'ri: provider tinglanmagan bo'lsa bo'sh qaytarardi
    // va ogohlantirish noto'g'ri "manfiy qoldiq" ko'rsatardi.
    final stock = Map.fromEntries(
      await stockQuery(ref.read(appDatabaseProvider)).get(),
    );
    final changes = correctionChanges(original, doc, stock);
    final ok = await _dialog(
      () => showPosConfirm(
        context: context,
        title: l10n.receivingConfirmCorrectionTitle,
        message: changes.isEmpty
            ? l10n.receivingNoChanges
            : l10n.receivingConfirmCorrectionMessage,
        content: changes.isEmpty ? null : _CorrectionTable(changes: changes),
        confirmLabel: l10n.receivingSaveCorrection,
        cancelLabel: l10n.actionKeep,
        icon: Icons.edit_note,
      ),
    );
    if (ok != true || !mounted) return;
    final by = await _approver(l10n.receivingEditNeedsApproval);
    if (by == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _store.postCorrection(
        widget.receiptId,
        by: by,
        storeId: ref.read(sessionProvider).device?.storeId,
      );
      if (!mounted) return;
      _toast(l10n.receivingCorrectedToast, PosTone.success);
      widget.onClose();
    } on ReceiptEmptyException {
      if (mounted) _toast(l10n.receivingCorrectionEmpty, PosTone.warning);
    } on ReceiptNotEditableException {
      if (mounted) _toast(l10n.receivingNotEditable, PosTone.warning);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message, PosTone tone) =>
      showPosToast(context, message: message, tone: tone);

  /// Holat banneri: tuzatish qoralamasi, tuzatilgan, bekor qilingan.
  Widget? _banner(ReceiptDoc doc) {
    final l10n = AppLocalizations.of(context);
    Widget withAction(NoticeBar bar, String label, String id, Key key) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bar,
            const SizedBox(height: PosSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: PosButton(
                key: key,
                label: label,
                size: PosButtonSize.s,
                variant: PosButtonVariant.secondary,
                onPressed: () => widget.onOpen?.call(id),
              ),
            ),
          ],
        );
    if (doc.isDraft && doc.isCorrection) {
      return NoticeBar(
        key: const ValueKey('receipt-correction-banner'),
        tone: PosTone.primary,
        icon: Icons.edit_note,
        text: l10n.receivingCorrectionBanner,
        rounded: true,
      );
    }
    if (doc.isCorrected) {
      return withAction(
        NoticeBar(
          tone: PosTone.neutral,
          icon: Icons.history,
          text: l10n.receivingCorrectedBanner,
          rounded: true,
        ),
        l10n.receivingOpenNewVersion,
        doc.correctedById!,
        const ValueKey('receipt-open-new-version'),
      );
    }
    if (doc.cancelled) {
      return NoticeBar(
        key: const ValueKey('receipt-cancelled-banner'),
        tone: PosTone.danger,
        icon: Icons.block,
        text: l10n.receivingCancelledBanner,
        rounded: true,
      );
    }
    final draft = doc.correctionDraftId;
    if (draft != null) {
      return withAction(
        NoticeBar(
          tone: PosTone.warning,
          icon: Icons.edit_note,
          text: l10n.receivingDraftExistsBanner,
          rounded: true,
        ),
        l10n.receivingContinueCorrection,
        draft,
        const ValueKey('receipt-continue-correction'),
      );
    }
    return null;
  }

  /// Tasdiqlangan amaldagi kirim: "Bekor qilish" va "Tahrirlash". Server
  /// bu imkoniyatni e'lon qilmagan bo'lsa (eski server) — izoh.
  List<Widget> _postedActions(ReceiptDoc doc, {bool expand = false}) {
    if (!doc.isActiveVersion) return const [];
    final l10n = AppLocalizations.of(context);
    final features = ref.watch(serverFeaturesProvider).value ?? const {};
    if (!features.contains(ServerFeature.receiptCorrections)) {
      return [
        Flexible(
          child: Text(
            l10n.receivingCorrectionUnavailable,
            style: PosTypography.small.copyWith(
              color: PosPalette.of(context).textSecondary,
            ),
          ),
        ),
      ];
    }
    final allowed = ref.watch(salesAllowedProvider) && !_busy;
    final cancel = PosButton(
      key: const ValueKey('receipt-cancel'),
      label: l10n.receivingCancelReceipt,
      icon: Icons.undo,
      variant: PosButtonVariant.ghost,
      onPressed: allowed ? () => unawaited(_cancel(doc)) : null,
    );
    final edit = PosButton(
      key: const ValueKey('receipt-edit'),
      label: l10n.receivingEdit,
      icon: Icons.edit_outlined,
      loading: _busy,
      expand: expand,
      onPressed: allowed ? () => unawaited(_edit(doc)) : null,
    );
    return [
      cancel,
      const SizedBox(width: PosSpacing.s),
      if (expand) Expanded(child: edit) else edit,
    ];
  }

  Widget _totals(ReceiptDoc doc) {
    final l10n = AppLocalizations.of(context);
    return Text(
      '${l10n.receivingLines(doc.lines.length)} · '
      '${l10n.receivingTotal(context.fmt.money(doc.totalCostTiyin))}',
      key: const ValueKey('receipt-total'),
      style: PosTypography.bodyStrong.copyWith(
        color: PosPalette.of(context).text,
      ),
    );
  }

  PosButton _postButton(ReceiptDoc doc, {bool expand = false}) => PosButton(
    key: const ValueKey('receipt-post'),
    label: doc.isCorrection
        ? AppLocalizations.of(context).receivingSaveCorrection
        : AppLocalizations.of(context).receivingPost,
    icon: Icons.check,
    loading: _busy,
    expand: expand,
    onPressed: _busy || !ref.watch(salesAllowedProvider)
        ? null
        : () => unawaited(_post(doc)),
  );

  Widget _wideFooter(ReceiptDoc doc) {
    final l10n = AppLocalizations.of(context);
    final row = Row(
      children: [
        Expanded(child: _totals(doc)),
        if (doc.isDraft) ...[
          PosButton(
            key: const ValueKey('receipt-delete'),
            label: doc.isCorrection
                ? l10n.receivingDiscardCorrection
                : l10n.receivingDelete,
            variant: PosButtonVariant.ghost,
            onPressed: _busy ? null : () => unawaited(_deleteDraft(doc)),
          ),
          const SizedBox(width: PosSpacing.s),
          _postButton(doc),
        ] else
          ..._postedActions(doc),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [if (doc.isDraft) const SalesBlockedNote(), row],
    );
  }

  /// Telefon: jami, ostida — o'chirish ikoni va to'liq kenglikdagi tasdiqlash.
  Widget _compactFooter(ReceiptDoc doc) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _totals(doc),
        if (doc.isDraft) ...[
          const SizedBox(height: PosSpacing.s),
          const SalesBlockedNote(),
          Row(
            children: [
              PosIconButton(
                key: const ValueKey('receipt-delete'),
                icon: Icons.delete_outline,
                tooltip: l10n.receivingDelete,
                variant: PosIconButtonVariant.outlined,
                onPressed: _busy ? null : () => unawaited(_deleteDraft(doc)),
              ),
              const SizedBox(width: PosSpacing.s),
              Expanded(child: _postButton(doc, expand: true)),
            ],
          ),
        ] else if (doc.isActiveVersion) ...[
          const SizedBox(height: PosSpacing.s),
          Row(children: _postedActions(doc, expand: true)),
        ],
      ],
    );
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
                  ReceiptBadges(
                    state: receiptStateOf(doc),
                    isCorrection: doc.isCorrection,
                  ),
                ],
              ),
              if (_banner(doc) case final banner?) ...[
                const SizedBox(height: PosSpacing.m),
                banner,
              ],
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
                  child: compact ? _compactFooter(doc) : _wideFooter(doc),
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
          l10n.receivingQtyUnit(line.unit.label(l10n)),
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

/// Tuzatishdagi bitta tovar: eski → yangi miqdor, qoldiq keyin.
class CorrectionChange {
  const CorrectionChange({
    required this.name,
    required this.unit,
    required this.oldMilli,
    required this.newMilli,
    required this.stockAfterMilli,
  });

  final String name;
  final UnitCode unit;
  final int oldMilli;
  final int newMilli;
  final int stockAfterMilli;

  int get deltaMilli => newMilli - oldMilli;
}

/// Miqdori o'zgargan tovarlar (asl → tuzatish). [stock] — hozirgi qoldiq.
List<CorrectionChange> correctionChanges(
  ReceiptDoc original,
  ReceiptDoc draft,
  Map<String, int> stock,
) {
  final names = <String, (String, UnitCode)>{};
  final before = <String, int>{};
  final after = <String, int>{};
  for (final l in original.lines) {
    names[l.productId] = (l.name, l.unit);
    before.update(
      l.productId,
      (v) => v + l.qtyMilli,
      ifAbsent: () => l.qtyMilli,
    );
  }
  for (final l in draft.lines) {
    names[l.productId] = (l.name, l.unit);
    after.update(
      l.productId,
      (v) => v + l.qtyMilli,
      ifAbsent: () => l.qtyMilli,
    );
  }
  return [
    for (final id in names.keys)
      if ((before[id] ?? 0) != (after[id] ?? 0))
        CorrectionChange(
          name: names[id]!.$1,
          unit: names[id]!.$2,
          oldMilli: before[id] ?? 0,
          newMilli: after[id] ?? 0,
          stockAfterMilli:
              (stock[id] ?? 0) + (after[id] ?? 0) - (before[id] ?? 0),
        ),
  ];
}

class _CorrectionTable extends StatelessWidget {
  const _CorrectionTable({required this.changes});

  final List<CorrectionChange> changes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    return Column(
      key: const ValueKey('correction-table'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in changes) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  c.name,
                  style: PosTypography.bodyStrong.copyWith(color: p.text),
                ),
              ),
              const SizedBox(width: PosSpacing.s),
              Text(
                '${fmt.qtyValue(c.oldMilli, c.unit)} → '
                '${fmt.qty(c.newMilli, c.unit)}',
                style: PosTypography.body.copyWith(color: p.text),
              ),
            ],
          ),
          if (c.stockAfterMilli < 0)
            Text(
              l10n.receivingNegativeStock(
                c.name,
                fmt.qty(c.stockAfterMilli, c.unit),
              ),
              style: PosTypography.small.copyWith(color: p.warningText),
            ),
          const SizedBox(height: PosSpacing.s),
        ],
      ],
    );
  }
}
