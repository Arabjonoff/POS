import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/refunds/refund_calculator.dart';
import 'package:pos_app/data/refunds/refund_writer.dart';
import 'package:pos_app/data/refunds/sale_lookup.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/pos/widgets/qty_dialog.dart';
import 'package:pos_app/features/shift/shift_providers.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Qaytarish natijasi (kassa ekrani xabari uchun).
class RefundResult {
  const RefundResult({required this.totalTiyin, required this.method});

  final int totalTiyin;
  final RefundMethod method;
}

/// F8: qaytarish (`docs/specs/sales-api.md`, T-045). Savdo chek raqami,
/// chekdagi shtrix-kod yoki oxirgi cheklar ro'yxatidan topiladi; qisman yoki
/// to'liq, sabab bilan, naqd yoki qarzdan ayirib. Menejer/ega tasdiqlaydi.
Future<RefundResult?> showRefundDialog(BuildContext context) =>
    showPosDialog<RefundResult>(
      context: context,
      maxWidth: RefundDialog.maxWidth,
      builder: (context) => const RefundDialog(),
    );

class RefundDialog extends ConsumerStatefulWidget {
  const RefundDialog({super.key});

  static const double maxWidth = 600;

  @override
  ConsumerState<RefundDialog> createState() => _RefundDialogState();
}

enum _Reason { defective, expired, changedMind, mistake }

class _RefundDialogState extends ConsumerState<RefundDialog> {
  final _number = TextEditingController();
  final _otherReason = TextEditingController();
  final _focus = FocusNode(debugLabel: 'refund');

  List<SaleSummary> _recent = const [];
  RefundableSale? _sale;
  Map<String, int> _qty = const {};
  _Reason? _reason;
  RefundMethod _method = RefundMethod.cash;

  /// Ichki oyna (miqdor, PIN) ochiq — raqamlar skaner buferiga tushmasin.
  bool _subDialog = false;
  bool _busy = false;
  bool _swallowEnter = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecent());
  }

  @override
  void dispose() {
    _number.dispose();
    _otherReason.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await ref.read(saleLookupProvider).recent();
    if (mounted) setState(() => _recent = recent);
  }

  // ---- Savdoni topish ---------------------------------------------------

  Future<void> _openNumber(String number) async {
    final id = await ref.read(saleLookupProvider).idByNumber(number);
    if (!mounted) return;
    if (id == null) {
      setState(() => _notice = AppLocalizations.of(context).refundNotFound);
      return;
    }
    await _openSale(id);
  }

  Future<void> _openSale(String id) async {
    final sale = await ref.read(saleLookupProvider).refundable(id);
    if (!mounted || sale == null) return;
    setState(() {
      _sale = sale;
      _qty = {for (final i in sale.items) i.saleItemId: 0};
      _method = RefundMethod.cash;
      _notice = null;
    });
    _focus.requestFocus();
  }

  void _onScan(ScanEvent event) {
    _swallowEnter = true;
    scheduleMicrotask(() => _swallowEnter = false);
    unawaited(_openNumber(event.code));
  }

  // ---- Hisob ------------------------------------------------------------

  RefundQuote? get _quote {
    final sale = _sale;
    if (sale == null) return null;
    try {
      return RefundQuote.of(sale, _qty);
    } on InvalidRefundException {
      return null;
    }
  }

  String get _reasonText {
    final l10n = AppLocalizations.of(context);
    final parts = [
      if (_reason != null) _reasonLabel(l10n, _reason!),
      if (_otherReason.text.trim().isNotEmpty) _otherReason.text.trim(),
    ];
    return parts.join('. ');
  }

  String _reasonLabel(AppLocalizations l10n, _Reason reason) =>
      switch (reason) {
        _Reason.defective => l10n.refundReasonDefective,
        _Reason.expired => l10n.refundReasonExpired,
        _Reason.changedMind => l10n.refundReasonChangedMind,
        _Reason.mistake => l10n.refundReasonMistake,
      };

  void _setQty(String saleItemId, int qty) => setState(() {
    _qty = {..._qty, saleItemId: qty};
    _notice = null;
  });

  void _all() {
    final sale = _sale;
    if (sale == null) return;
    setState(() {
      _qty = {for (final i in sale.items) i.saleItemId: i.remainingQtyMilli};
      _notice = null;
    });
  }

  Future<void> _editQty(RefundableItem item) async {
    final l10n = AppLocalizations.of(context);
    final unit = UnitCode.fromCode(item.unit);
    setState(() => _subDialog = true);
    final qty = await showQtyDialog(
      context,
      productName: item.name,
      weighted: unit.fractional,
      unit: unit.label(l10n),
      initialMilli: _qty[item.saleItemId],
    );
    if (!mounted) return;
    setState(() => _subDialog = false);
    if (qty != null) {
      _setQty(item.saleItemId, qty.clamp(0, item.remainingQtyMilli));
    }
    _focus.requestFocus();
  }

  // ---- Yakunlash --------------------------------------------------------

  Future<void> _submit() async {
    final sale = _sale;
    if (sale == null || _busy || _subDialog) return;
    final l10n = AppLocalizations.of(context);
    final quote = _quote;
    if (quote == null) {
      setState(() => _notice = l10n.refundChooseItems);
      return;
    }
    final reason = _reasonText;
    if (reason.isEmpty) {
      setState(() => _notice = l10n.refundChooseReason);
      return;
    }
    final method = _method == RefundMethod.debt && quote.debtAllowed(sale)
        ? RefundMethod.debt
        : RefundMethod.cash;
    final user = ref.read(sessionProvider).user;
    final shift = await openShiftNow(ref);
    if (!mounted) return;
    if (user == null || shift == null) {
      setState(() => _notice = l10n.refundFailed);
      return;
    }

    var approvedBy = DiscountPolicy.canApprove(user.role) ? user.id : null;
    if (approvedBy == null) {
      setState(() => _subDialog = true);
      approvedBy = await requestManagerApproval(
        context,
        reason: l10n.refundNeedsApproval,
      );
      if (!mounted) return;
      setState(() => _subDialog = false);
      if (approvedBy == null) return;
    }

    setState(() => _busy = true);
    try {
      final done = await ref
          .read(refundWriterProvider)
          .record(
            sale: sale,
            quote: quote,
            method: method,
            shiftId: shift.id,
            cashierId: user.id,
            reason: reason,
            approvedBy: approvedBy,
          );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(RefundResult(totalTiyin: done.totalTiyin, method: method));
    } on Exception {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = l10n.refundFailed;
      });
    }
  }

  static bool get _inTextField =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>() !=
      null;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _inTextField) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_swallowEnter) {
        _swallowEnter = false;
      } else if (_sale != null) {
        unawaited(_submit());
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---- Maket ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sale = _sale;
    final quote = _quote;
    return ScanListener(
      enabled: !_subDialog,
      onScan: _onScan,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: PosDialog(
          icon: Icons.assignment_return_outlined,
          title: sale == null
              ? l10n.refundTitle
              : '${l10n.refundTitle} · ${sale.number}',
          message: sale == null ? l10n.refundFindHint : null,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sale == null) ..._find(l10n) else ..._refund(l10n, sale),
              if (_notice != null) ...[
                const SizedBox(height: PosSpacing.m),
                _Notice(_notice!),
              ],
            ],
          ),
          actions: [
            if (sale != null)
              PosButton(
                label: l10n.refundOtherCheck,
                variant: PosButtonVariant.ghost,
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _sale = null;
                        _notice = null;
                        unawaited(_loadRecent());
                      }),
              ),
            PosButton(
              label: l10n.actionCancel,
              variant: PosButtonVariant.secondary,
              shortcut: 'Esc',
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
            ),
            if (sale != null && !sale.fullyRefunded)
              PosButton(
                key: const ValueKey('refund-confirm'),
                label: l10n.refundConfirm,
                icon: Icons.assignment_return_outlined,
                variant: PosButtonVariant.danger,
                shortcut: 'Enter',
                loading: _busy,
                onPressed: quote != null && !_busy
                    ? () => unawaited(_submit())
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _find(AppLocalizations l10n) {
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: PosTextField(
              key: const ValueKey('refund-number'),
              controller: _number,
              label: l10n.refundNumber,
              hint: l10n.refundNumberHint,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => unawaited(_openNumber(v)),
            ),
          ),
          const SizedBox(width: PosSpacing.s),
          PosButton(
            label: l10n.refundFind,
            icon: Icons.search,
            variant: PosButtonVariant.secondary,
            onPressed: () => unawaited(_openNumber(_number.text)),
          ),
        ],
      ),
      const SizedBox(height: PosSpacing.l),
      Text(
        l10n.refundRecent,
        style: PosTypography.smallStrong.copyWith(color: p.textSecondary),
      ),
      const SizedBox(height: PosSpacing.xs),
      if (_recent.isEmpty)
        PosEmptyState(
          icon: Icons.receipt_long_outlined,
          title: l10n.refundNoSales,
        )
      else
        for (final s in _recent)
          PosListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: s.number,
            subtitle: [
              fmt.dateTime(s.soldAt),
              if (s.status == 'partially_refunded') l10n.refundStatusPartial,
              if (s.status == 'refunded') l10n.refundStatusFull,
            ].join(' · '),
            trailing: PosMoneyText(
              amount: s.totalTiyin,
              currency: fmt.currency,
            ),
            onTap: () => unawaited(_openSale(s.id)),
          ),
    ];
  }

  List<Widget> _refund(AppLocalizations l10n, RefundableSale sale) {
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    if (sale.fullyRefunded) {
      return [
        PosEmptyState(
          icon: Icons.assignment_turned_in_outlined,
          title: l10n.refundFullyRefunded,
        ),
      ];
    }
    final quote = _quote;
    final debtAllowed = quote?.debtAllowed(sale) ?? false;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(
        top: PosSpacing.m,
        bottom: PosSpacing.xs,
      ),
      child: Text(
        text,
        style: PosTypography.smallStrong.copyWith(color: p.textSecondary),
      ),
    );

    return [
      Row(
        children: [
          Expanded(
            child: Text(
              fmt.dateTime(sale.soldAt),
              style: PosTypography.small.copyWith(color: p.textSecondary),
            ),
          ),
          PosButton(
            key: const ValueKey('refund-all'),
            label: l10n.refundAll,
            size: PosButtonSize.s,
            variant: PosButtonVariant.secondary,
            onPressed: _all,
          ),
        ],
      ),
      const SizedBox(height: PosSpacing.s),
      for (final item in sale.items)
        if (item.remainingQtyMilli > 0)
          _ItemRow(
            item: item,
            qtyMilli: _qty[item.saleItemId] ?? 0,
            onChanged: (q) => _setQty(item.saleItemId, q),
            onEdit: () => unawaited(_editQty(item)),
          ),
      label(l10n.refundReason),
      Wrap(
        spacing: PosSpacing.s,
        runSpacing: PosSpacing.s,
        children: [
          for (final r in _Reason.values)
            PosButton(
              key: ValueKey('refund-reason-${r.name}'),
              label: _reasonLabel(l10n, r),
              size: PosButtonSize.s,
              variant: r == _reason
                  ? PosButtonVariant.primary
                  : PosButtonVariant.secondary,
              onPressed: () => setState(() {
                _reason = r == _reason ? null : r;
                _notice = null;
              }),
            ),
        ],
      ),
      const SizedBox(height: PosSpacing.s),
      PosTextField(
        controller: _otherReason,
        hint: l10n.refundReasonOther,
        onChanged: (_) => setState(() => _notice = null),
      ),
      if (sale.debtLeftTiyin > 0) ...[
        label(l10n.refundMethod),
        Row(
          children: [
            for (final (m, text) in [
              (RefundMethod.cash, l10n.refundMethodCash),
              (RefundMethod.debt, l10n.refundMethodDebt),
            ]) ...[
              if (m == RefundMethod.debt) const SizedBox(width: PosSpacing.s),
              Expanded(
                child: PosButton(
                  key: ValueKey('refund-method-${m.name}'),
                  label: text,
                  size: PosButtonSize.s,
                  expand: true,
                  variant: m == _method
                      ? PosButtonVariant.primary
                      : PosButtonVariant.secondary,
                  onPressed: m == RefundMethod.debt && !debtAllowed
                      ? null
                      : () => setState(() => _method = m),
                ),
              ),
            ],
          ],
        ),
      ],
      const SizedBox(height: PosSpacing.l),
      Row(
        children: [
          Expanded(
            child: Text(
              l10n.refundTotal,
              style: PosTypography.bodyStrong.copyWith(color: p.text),
            ),
          ),
          PosMoneyText(
            key: const ValueKey('refund-total'),
            amount: quote?.totalTiyin ?? 0,
            currency: fmt.currency,
            size: PosMoneySize.large,
            tone: quote == null ? null : PosTone.danger,
          ),
        ],
      ),
    ];
  }
}

/// Qaytariladigan qator: nom, sotilgan/qolgan, miqdor (− / + yoki bosib).
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.qtyMilli,
    required this.onChanged,
    required this.onEdit,
  });

  final RefundableItem item;
  final int qtyMilli;
  final ValueChanged<int> onChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final unit = UnitCode.fromCode(item.unit);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: PosTypography.bodyStrong.copyWith(color: p.text),
        ),
        Text(
          [
            l10n.refundSold(fmt.qty(item.qtyMilli, unit)),
            if (item.refundedQtyMilli > 0)
              l10n.refundLeft(fmt.qty(item.remainingQtyMilli, unit)),
          ].join(' · '),
          style: PosTypography.small.copyWith(color: p.textSecondary),
        ),
      ],
    );
    final stepper = PosQtyStepper(
      key: ValueKey('refund-qty-${item.saleItemId}'),
      valueMilli: qtyMilli,
      onChanged: onChanged,
      maxMilli: item.remainingQtyMilli,
      stepMilli: unit.fractional ? 100 : 1000,
      weighted: unit.fractional,
      unit: unit.label(l10n),
      onValueTap: onEdit,
      decrementTooltip: l10n.actionDecrease,
      incrementTooltip: l10n.actionIncrease,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 420
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const SizedBox(height: PosSpacing.xs),
                  Align(alignment: Alignment.centerRight, child: stepper),
                ],
              )
            : Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: PosSpacing.s),
                  stepper,
                ],
              ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = PosPalette.of(context).tone(PosTone.warning);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.soft,
          borderRadius: PosRadius.controlAll,
        ),
        child: Padding(
          padding: const EdgeInsets.all(PosSpacing.m),
          child: Row(
            children: [
              Icon(
                PosToast.iconFor(PosTone.warning),
                size: PosSizes.iconM,
                color: colors.onSoft,
              ),
              const SizedBox(width: PosSpacing.s),
              Expanded(
                child: Text(
                  text,
                  style: PosTypography.body.copyWith(color: colors.onSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
