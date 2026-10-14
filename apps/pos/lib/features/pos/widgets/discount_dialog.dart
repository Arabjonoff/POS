import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/features/common/money_input.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

enum DiscountTarget { line, check }

/// Chegirma oynasi natijasi; [discount] `null` — olib tashlash.
class DiscountChoice {
  const DiscountChoice(this.target, this.discount);

  final DiscountTarget target;
  final Discount? discount;
}

/// F3: qatorga (tanlangan bo'lsa) yoki butun chekka, foiz yoki summa.
Future<DiscountChoice?> showDiscountDialog(
  BuildContext context, {
  required int lineBase,
  required int checkBase,
  required bool hasLine,
  Discount? lineDiscount,
  Discount? checkDiscount,
}) => showPosDialog<DiscountChoice>(
  context: context,
  builder: (context) => _DiscountDialog(
    lineBase: lineBase,
    checkBase: checkBase,
    hasLine: hasLine,
    lineDiscount: lineDiscount,
    checkDiscount: checkDiscount,
  ),
);

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({
    required this.lineBase,
    required this.checkBase,
    required this.hasLine,
    this.lineDiscount,
    this.checkDiscount,
  });

  final int lineBase;
  final int checkBase;
  final bool hasLine;
  final Discount? lineDiscount;
  final Discount? checkDiscount;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late DiscountTarget _target = widget.hasLine
      ? DiscountTarget.line
      : DiscountTarget.check;
  late bool _percent;
  late int _percentValue;
  late int _amountTiyin;

  Discount? get _existing => _target == DiscountTarget.line
      ? widget.lineDiscount
      : widget.checkDiscount;

  int get _base =>
      _target == DiscountTarget.line ? widget.lineBase : widget.checkBase;

  Discount? get _discount {
    if (_percent) {
      return _percentValue > 0 ? Discount.percent(_percentValue * 100) : null;
    }
    return _amountTiyin > 0 ? Discount.amount(_amountTiyin) : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final d = _existing;
    _percent = d == null || d.isPercent;
    _percentValue = d != null && d.isPercent ? d.percentBp ~/ 100 : 0;
    _amountTiyin = d != null && !d.isPercent ? d.amountTiyin : 0;
  }

  void _percentKey(String digit) {
    final next = int.parse('$_percentValue$digit');
    if (next > 100) return;
    setState(() => _percentValue = next);
  }

  KeyEventResult _onPercentKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      setState(() => _percentValue ~/= 10);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _apply();
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char != null && char.length == 1 && '0123456789'.contains(char)) {
      _percentKey(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _apply() {
    final d = _discount;
    if (d == null) return;
    Navigator.of(context).pop(DiscountChoice(_target, d));
  }

  Widget _toggle<T>(T value, T group, String label, ValueChanged<T> onTap) =>
      Expanded(
        child: PosButton(
          label: label,
          size: PosButtonSize.s,
          variant: value == group
              ? PosButtonVariant.primary
              : PosButtonVariant.secondary,
          expand: true,
          onPressed: () => onTap(value),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final discount = _discount;
    final value = discount?.of(_base) ?? 0;

    return PosDialog(
      icon: Icons.percent,
      title: l10n.posDiscount,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.hasLine) ...[
            Row(
              children: [
                _toggle(
                  DiscountTarget.line,
                  _target,
                  l10n.posDiscountLine,
                  (t) => setState(() {
                    _target = t;
                    _load();
                  }),
                ),
                const SizedBox(width: PosSpacing.s),
                _toggle(
                  DiscountTarget.check,
                  _target,
                  l10n.posDiscountCheck,
                  (t) => setState(() {
                    _target = t;
                    _load();
                  }),
                ),
              ],
            ),
            const SizedBox(height: PosSpacing.s),
          ],
          Row(
            children: [
              _toggle(
                true,
                _percent,
                l10n.posDiscountPercent,
                (v) => setState(() => _percent = v),
              ),
              const SizedBox(width: PosSpacing.s),
              _toggle(
                false,
                _percent,
                l10n.posDiscountAmount,
                (v) => setState(() => _percent = v),
              ),
            ],
          ),
          const SizedBox(height: PosSpacing.m),
          if (_percent)
            Focus(
              key: const ValueKey('percent'),
              autofocus: true,
              onKeyEvent: _onPercentKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PosSpacing.l,
                      vertical: PosSpacing.m,
                    ),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: PosRadius.inputAll,
                      border: Border.all(color: p.focus, width: 2),
                    ),
                    child: Text(
                      fmt.percent(_percentValue),
                      textAlign: TextAlign.right,
                      style: PosTypography.h1.copyWith(
                        color: p.text,
                        fontFeatures: PosTypography.tabular,
                      ),
                    ),
                  ),
                  const SizedBox(height: PosSpacing.m),
                  PosNumericKeypad(
                    onKey: _percentKey,
                    onBackspace: () => setState(() => _percentValue ~/= 10),
                    onClear: () => setState(() => _percentValue = 0),
                    backspaceTooltip: l10n.actionBackspace,
                  ),
                ],
              ),
            )
          else
            MoneyInput(
              key: const ValueKey('amount'),
              valueTiyin: _amountTiyin,
              onChanged: (v) => setState(() => _amountTiyin = v),
              onSubmit: _apply,
            ),
          const SizedBox(height: PosSpacing.m),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.posDiscount,
                  style: PosTypography.bodyStrong.copyWith(color: p.text),
                ),
              ),
              PosMoneyText(
                amount: -value,
                currency: fmt.currency,
                size: PosMoneySize.medium,
                tone: PosTone.success,
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_existing != null)
          PosButton(
            label: l10n.posDiscountRemove,
            variant: PosButtonVariant.ghost,
            onPressed: () =>
                Navigator.of(context).pop(DiscountChoice(_target, null)),
          ),
        PosButton(
          label: l10n.actionCancel,
          variant: PosButtonVariant.secondary,
          shortcut: 'Esc',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PosButton(
          label: l10n.posDiscountApply,
          shortcut: 'Enter',
          onPressed: discount == null ? null : _apply,
        ),
      ],
    );
  }
}
