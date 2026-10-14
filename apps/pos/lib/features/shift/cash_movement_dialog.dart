import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/shifts/shift_service.dart';
import 'package:pos_app/features/common/money_input.dart';
import 'package:pos_app/features/shift/shift_providers.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// "Kassaga … kiritildi" / "Kassadan … chiqarildi".
void showCashMovementDone(BuildContext context, CashMovementResult result) {
  final l10n = AppLocalizations.of(context);
  final amount = context.fmt.money(result.amountTiyin);
  showPosToast(
    context,
    message: result.type == CashMovementType.cashIn
        ? l10n.cashDoneIn(amount)
        : l10n.cashDoneOut(amount),
    tone: PosTone.success,
  );
}

/// Yozilgan harakat (xabar uchun).
class CashMovementResult {
  const CashMovementResult(this.type, this.amountTiyin);

  final CashMovementType type;
  final int amountTiyin;
}

/// F9: kassaga pul kiritish yoki chiqarish, sabab bilan
/// (`docs/specs/shifts.md`). Chiqarish kassadagi naqddan oshmaydi.
Future<CashMovementResult?> showCashMovementDialog(
  BuildContext context, {
  CashMovementType type = CashMovementType.cashOut,
}) => showPosDialog<CashMovementResult>(
  context: context,
  builder: (context) => CashMovementDialog(initialType: type),
);

class CashMovementDialog extends ConsumerStatefulWidget {
  const CashMovementDialog({
    this.initialType = CashMovementType.cashOut,
    super.key,
  });

  final CashMovementType initialType;

  @override
  ConsumerState<CashMovementDialog> createState() => _CashMovementDialogState();
}

enum _Reason { collection, expense, change }

class _CashMovementDialogState extends ConsumerState<CashMovementDialog> {
  late CashMovementType _type = widget.initialType;
  final _other = TextEditingController();
  int _amount = 0;
  _Reason? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, _Reason r) => switch (r) {
    _Reason.collection => l10n.cashReasonCollection,
    _Reason.expense => l10n.cashReasonExpense,
    _Reason.change => l10n.cashReasonChange,
  };

  String _reasonText(AppLocalizations l10n) => [
    if (_reason != null) _reasonLabel(l10n, _reason!),
    if (_other.text.trim().isNotEmpty) _other.text.trim(),
  ].join('. ');

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (_amount <= 0) {
      setState(() => _error = l10n.cashEnterAmount);
      return;
    }
    final reason = _reasonText(l10n);
    if (reason.isEmpty) {
      setState(() => _error = l10n.cashChooseReason);
      return;
    }
    final shift = ref.read(currentShiftProvider).value;
    final user = ref.read(sessionProvider).user;
    if (shift == null || user == null) {
      setState(() => _error = l10n.cashFailed);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(shiftServiceProvider)
          .moveCash(
            shiftId: shift.id,
            type: _type,
            amountTiyin: _amount,
            by: user.id,
            reason: reason,
          );
      ref.invalidate(shiftReportProvider(shift.id));
      if (mounted) {
        Navigator.of(context).pop(CashMovementResult(_type, _amount));
      }
    } on CashOutExceedsCashException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.cashExceeds(context.fmt.money(e.availableTiyin));
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.cashFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final shift = ref.watch(currentShiftProvider).value;
    final expected = shift == null
        ? null
        : ref.watch(shiftReportProvider(shift.id)).value?.expectedCash;
    final error = _error;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: PosSpacing.m, bottom: PosSpacing.xs),
      child: Text(
        text,
        style: PosTypography.smallStrong.copyWith(color: p.textSecondary),
      ),
    );

    return PosDialog(
      icon: Icons.point_of_sale_outlined,
      title: l10n.cashTitle,
      message: expected == null
          ? null
          : l10n.cashAvailable(context.fmt.money(expected)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (t, text) in [
                (CashMovementType.cashIn, l10n.cashIn),
                (CashMovementType.cashOut, l10n.cashOut),
              ]) ...[
                if (t == CashMovementType.cashOut)
                  const SizedBox(width: PosSpacing.s),
                Expanded(
                  child: PosButton(
                    key: ValueKey('cash-${t.code}'),
                    label: text,
                    icon: t == CashMovementType.cashIn
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    size: PosButtonSize.s,
                    expand: true,
                    variant: t == _type
                        ? PosButtonVariant.primary
                        : PosButtonVariant.secondary,
                    onPressed: () => setState(() {
                      _type = t;
                      _error = null;
                    }),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: PosSpacing.m),
          MoneyInput(
            valueTiyin: _amount,
            onChanged: (v) => setState(() {
              _amount = v;
              _error = null;
            }),
            onSubmit: () => unawaited(_submit()),
          ),
          label(l10n.cashReason),
          Wrap(
            spacing: PosSpacing.s,
            runSpacing: PosSpacing.s,
            children: [
              for (final r in _Reason.values)
                PosButton(
                  key: ValueKey('cash-reason-${r.name}'),
                  label: _reasonLabel(l10n, r),
                  size: PosButtonSize.s,
                  variant: r == _reason
                      ? PosButtonVariant.primary
                      : PosButtonVariant.secondary,
                  onPressed: () => setState(() {
                    _reason = r == _reason ? null : r;
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: PosSpacing.s),
          PosTextField(
            controller: _other,
            hint: l10n.cashReasonOther,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => unawaited(_submit()),
          ),
          if (error != null) ...[
            const SizedBox(height: PosSpacing.m),
            Text(
              error,
              style: PosTypography.bodyStrong.copyWith(color: p.dangerText),
            ),
          ],
        ],
      ),
      actions: [
        PosButton(
          label: l10n.actionCancel,
          variant: PosButtonVariant.secondary,
          shortcut: 'Esc',
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        PosButton(
          key: const ValueKey('cash-confirm'),
          label: _type == CashMovementType.cashIn ? l10n.cashIn : l10n.cashOut,
          shortcut: 'Enter',
          loading: _busy,
          onPressed: _busy ? null : () => unawaited(_submit()),
        ),
      ],
    );
  }
}
