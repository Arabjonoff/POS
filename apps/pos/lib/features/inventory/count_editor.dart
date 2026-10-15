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
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/inventory/count_store.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/products/product_card.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

final StreamProviderFamily<CountDoc?, String> countProvider = StreamProvider
    .autoDispose
    .family<CountDoc?, String>(
      (ref, id) => ref.watch(countStoreProvider).watch(id),
    );

/// Inventarizatsiya tahrirlovchisi: skan → sanalgan +1, miqdorni yozish,
/// farq hisoboti (tizimdagi va sanalgan), sanalmaganlar, tasdiqlash.
class CountEditor extends ConsumerStatefulWidget {
  const CountEditor({required this.countId, required this.onClose, super.key});

  final String countId;
  final VoidCallback onClose;

  @override
  ConsumerState<CountEditor> createState() => _CountEditorState();
}

class _CountEditorState extends ConsumerState<CountEditor> {
  final _search = TextEditingController();
  final _feedback = PosScanFeedbackController();
  bool _dialogOpen = false;
  bool _busy = false;
  bool _showUncounted = false;

  CountStore get _store => ref.read(countStoreProvider);

  @override
  void dispose() {
    _search.dispose();
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _add(String productId, {int qtyMilli = 1000}) async {
    await _store.addCounted(widget.countId, productId, qtyMilli: qtyMilli);
    _feedback.flash(PosScanResult.success);
    unawaited(ref.read(scanSignalProvider).success());
  }

  void _warn(String message) {
    _feedback.flash(PosScanResult.warning);
    unawaited(ref.read(scanSignalProvider).notFound());
    showPosToast(context, message: message, tone: PosTone.warning);
  }

  Future<void> _onScan(ScanEvent event) async {
    final l10n = AppLocalizations.of(context);
    if (Barcodes.check(event.code) == BarcodeCheck.invalidCheckDigit) {
      _warn(l10n.scanInvalidCode);
      return;
    }
    final catalog =
        ref.read(productCatalogProvider).value ?? ProductCatalog(const []);
    final match = catalog.byCode(event.code);
    if (match == null) {
      _warn(l10n.inventoryNotFound);
      return;
    }
    await _add(match.product.id, qtyMilli: match.qtyMilli ?? 1000);
  }

  void _onTyping(String text) {
    final value = _search.text + text;
    _search.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  Future<void> _post(CountDoc doc) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (doc.lines.isEmpty) {
      showPosToast(
        context,
        message: l10n.inventoryEmptyPost,
        tone: PosTone.warning,
      );
      return;
    }
    final session = ref.read(sessionProvider);
    final user = session.user;
    if (user == null) return;
    var by = DiscountPolicy.canApprove(user.role) ? user.id : null;
    if (by == null) {
      setState(() => _dialogOpen = true);
      by = await requestManagerApproval(
        context,
        reason: l10n.inventoryNeedsApproval,
      );
      if (mounted) setState(() => _dialogOpen = false);
    }
    if (by == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _store.post(
        widget.countId,
        by: by,
        storeId: session.device?.storeId,
      );
      if (!mounted) return;
      showPosToast(
        context,
        message: l10n.inventoryPostedToast,
        tone: PosTone.success,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final doc = ref.watch(countProvider(widget.countId)).value;
    if (doc == null) return const Center(child: CircularProgressIndicator());
    final draft = doc.isDraft;
    final catalog =
        ref.watch(productCatalogProvider).value ?? ProductCatalog(const []);
    final results = _search.text.trim().isEmpty
        ? const <CatalogProduct>[]
        : catalog.search(_search.text).take(8).toList();

    final summary = l10n.inventorySummary(
      doc.lines.length,
      doc.uncounted.length,
      doc.surplusCount,
      doc.shortageCount,
    );

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
                    key: const ValueKey('count-back'),
                    icon: Icons.arrow_back,
                    tooltip: l10n.inventoryBack,
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: PosSpacing.s),
                  Expanded(
                    child: Text(
                      [
                        l10n.inventoryCount(
                          fmt.dateTime(doc.postedAt ?? doc.createdAt),
                        ),
                        doc.categoryName ?? l10n.inventoryScopeAll,
                      ].join(' · '),
                      maxLines: 2,
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
              const SizedBox(height: PosSpacing.s),
              Text(
                summary,
                key: const ValueKey('count-summary'),
                style: PosTypography.bodyStrong.copyWith(
                  color: p.textSecondary,
                ),
              ),
              if (draft) ...[
                const SizedBox(height: PosSpacing.m),
                PosSearchField(
                  key: const ValueKey('count-search'),
                  controller: _search,
                  hint: l10n.receivingSearchHint,
                  clearTooltip: l10n.actionClear,
                  onChanged: (_) => setState(() {}),
                ),
                for (final product in results)
                  PosListTile(
                    title: product.name,
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
                child: ListView(
                  children: [
                    if (doc.lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(PosSpacing.xl),
                        child: PosEmptyState(
                          icon: Icons.qr_code_scanner,
                          title: l10n.inventoryEmptyLines,
                        ),
                      ),
                    for (final line in doc.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: PosSpacing.s),
                        child: _CountRow(
                          key: ValueKey(line.id),
                          line: line,
                          editable: draft,
                        ),
                      ),
                    if (draft && doc.uncounted.isNotEmpty) ...[
                      PosListTile(
                        key: const ValueKey('count-uncounted'),
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: l10n.inventoryUncounted(doc.uncounted.length),
                        subtitle: l10n.inventoryUncountedNote,
                        trailing: Icon(
                          _showUncounted
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onTap: () =>
                            setState(() => _showUncounted = !_showUncounted),
                      ),
                      if (_showUncounted)
                        for (final u in doc.uncounted)
                          PosListTile(
                            key: ValueKey('uncounted-${u.productId}'),
                            title: u.name,
                            subtitle: l10n.inventorySystem(
                              fmt.qty(u.stockMilli, u.unit),
                            ),
                            trailing: const Icon(Icons.add),
                            onTap: () => unawaited(
                              _store.addCounted(
                                widget.countId,
                                u.productId,
                                qtyMilli: 0,
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              if (draft) const SalesBlockedNote(),
              if (draft)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: p.border)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: PosSpacing.m),
                    child: Row(
                      children: [
                        PosIconButton(
                          key: const ValueKey('count-delete'),
                          icon: Icons.delete_outline,
                          tooltip: l10n.inventoryDelete,
                          variant: PosIconButtonVariant.outlined,
                          onPressed: _busy
                              ? null
                              : () async {
                                  await _store.deleteDraft(widget.countId);
                                  widget.onClose();
                                },
                        ),
                        const SizedBox(width: PosSpacing.s),
                        Expanded(
                          child: PosButton(
                            key: const ValueKey('count-post'),
                            label: l10n.inventoryPost,
                            icon: Icons.check,
                            expand: true,
                            loading: _busy,
                            onPressed: _busy || !ref.watch(salesAllowedProvider)
                                ? null
                                : () => unawaited(_post(doc)),
                          ),
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

/// Qator: nom, tizimda, sanalgan (tahrirlanadi), farq (rangli).
class _CountRow extends ConsumerStatefulWidget {
  const _CountRow({required this.line, required this.editable, super.key});

  final CountLine line;
  final bool editable;

  @override
  ConsumerState<_CountRow> createState() => _CountRowState();
}

class _CountRowState extends ConsumerState<_CountRow> {
  late final _counted = TextEditingController(text: _text(widget.line));
  bool _bad = false;

  static String _text(CountLine l) {
    final text = formatQtyInput(l.countedMilli, fractional: l.unit.fractional);
    return text.isEmpty ? '0' : text;
  }

  @override
  void didUpdateWidget(_CountRow old) {
    super.didUpdateWidget(old);
    final parsed = parseQtyMilli(
      _counted.text,
      fractional: widget.line.unit.fractional,
    );
    if (widget.line.countedMilli != old.line.countedMilli &&
        parsed != widget.line.countedMilli) {
      _counted.text = _text(widget.line);
    }
  }

  @override
  void dispose() {
    _counted.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final qty = parseQtyMilli(text, fractional: widget.line.unit.fractional);
    setState(() => _bad = qty == null);
    if (qty != null) {
      unawaited(ref.read(countStoreProvider).setCounted(widget.line.id, qty));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final line = widget.line;
    final diff = line.diffMilli;
    final diffText = diff > 0
        ? '+${fmt.qty(diff, line.unit)}'
        : fmt.qty(diff, line.unit);
    final tone = diff == 0
        ? PosTone.neutral
        : (diff > 0 ? PosTone.warning : PosTone.danger);

    return PosCard(
      padding: const EdgeInsets.all(PosSpacing.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PosTypography.bodyStrong.copyWith(color: p.text),
                ),
                const SizedBox(height: PosSpacing.xs),
                Wrap(
                  spacing: PosSpacing.s,
                  runSpacing: PosSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.inventorySystem(
                        fmt.qty(line.expectedMilli, line.unit),
                      ),
                      style: PosTypography.small.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                    PosBadge(
                      key: ValueKey('diff-${line.productId}'),
                      label: l10n.inventoryDiff(diffText),
                      tone: tone,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: PosSpacing.s),
          if (widget.editable) ...[
            SizedBox(
              width: 120,
              child: PosTextField(
                key: ValueKey('counted-${line.productId}'),
                controller: _counted,
                label: l10n.inventoryCountedUnit(line.unit.label(l10n)),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]')),
                ],
                textAlign: TextAlign.right,
                errorText: _bad ? l10n.productErrQty : null,
                onChanged: _onChanged,
              ),
            ),
            PosIconButton(
              icon: Icons.delete_outline,
              tooltip: l10n.receivingRemoveLine,
              onPressed: () => unawaited(
                ref.read(countStoreProvider).removeLine(line.id),
              ),
            ),
          ] else
            Text(
              fmt.qty(line.countedMilli, line.unit),
              style: PosTypography.bodyStrong.copyWith(
                color: p.text,
                fontFeatures: PosTypography.tabular,
              ),
            ),
        ],
      ),
    );
  }
}
