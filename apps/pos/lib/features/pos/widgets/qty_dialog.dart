import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/core/money/money.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Miqdor kiritish (F2 yoki qatordagi miqdorni bosish; vaznli tovar
/// qo'shishda — kg). Natija `qty_milli` yoki `null` (bekor).
Future<int?> showQtyDialog(
  BuildContext context, {
  required String productName,
  required bool weighted,
  required String unit,
  int? initialMilli,
}) => showPosDialog<int>(
  context: context,
  builder: (context) => _QtyDialog(
    productName: productName,
    weighted: weighted,
    unit: unit,
    initialMilli: initialMilli,
  ),
);

class _QtyDialog extends StatefulWidget {
  const _QtyDialog({
    required this.productName,
    required this.weighted,
    required this.unit,
    this.initialMilli,
  });

  final String productName;
  final bool weighted;
  final String unit;
  final int? initialMilli;

  @override
  State<_QtyDialog> createState() => _QtyDialogState();
}

class _QtyDialogState extends State<_QtyDialog> {
  /// Kiritilgan matn (`1`, `0,25`). Bo'sh — boshlang'ich qiymat ko'rinadi,
  /// birinchi tugma uni almashtiradi.
  String _text = '';

  static const String _comma = ',';
  static const int _maxIntDigits = 5;

  int? get _value {
    if (_text.isEmpty) return widget.initialMilli;
    final parts = _text.split(_comma);
    final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]) ?? 0;
    final frac = parts.length > 1 ? parts[1].padRight(3, '0') : '000';
    final value = whole * Money.qtyScale + int.parse(frac);
    return value > 0 ? value : null;
  }

  void _key(String key) {
    final next = _text + key;
    if (key == _comma) {
      if (!widget.weighted || _text.contains(_comma)) return;
      setState(() => _text = _text.isEmpty ? '0$_comma' : next);
      return;
    }
    final parts = next.split(_comma);
    if (parts[0].length > _maxIntDigits) return;
    if (parts.length > 1 && parts[1].length > 3) return;
    setState(() => _text = next.replaceFirst(RegExp(r'^0+(?=\d)'), ''));
  }

  void _backspace() {
    if (_text.isEmpty) return;
    setState(() => _text = _text.substring(0, _text.length - 1));
  }

  void _submit() {
    final value = _value;
    if (value != null) Navigator.of(context).pop(value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char == null || char.length != 1) return KeyEventResult.ignored;
    if ('0123456789'.contains(char)) {
      _key(char);
      return KeyEventResult.handled;
    }
    if (char == ',' || char == '.') {
      _key(_comma);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final value = _value;
    final shown = _text.isNotEmpty
        ? '$_text ${widget.unit}'
        : (value == null
              ? ''
              : PosFormat.qtyWithUnit(
                  value,
                  unit: widget.unit,
                  weighted: widget.weighted,
                ));
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: PosDialog(
        icon: widget.weighted ? Icons.scale_outlined : Icons.numbers,
        title: widget.weighted ? l10n.posWeightTitle : l10n.posQtyTitle,
        message: widget.productName,
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
              child: Semantics(
                liveRegion: true,
                child: Text(
                  shown,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: PosTypography.h1.copyWith(
                    color: _text.isEmpty ? p.textSecondary : p.text,
                    fontFeatures: PosTypography.tabular,
                  ),
                ),
              ),
            ),
            const SizedBox(height: PosSpacing.m),
            PosNumericKeypad(
              onKey: _key,
              onBackspace: _backspace,
              onClear: () => setState(() => _text = ''),
              backspaceTooltip: l10n.actionBackspace,
              extraKey: widget.weighted ? _comma : null,
            ),
          ],
        ),
        actions: [
          PosButton(
            label: l10n.actionCancel,
            variant: PosButtonVariant.secondary,
            shortcut: 'Esc',
            onPressed: () => Navigator.of(context).pop(),
          ),
          PosButton(
            label: l10n.posQtyApply,
            shortcut: 'Enter',
            onPressed: value == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}
