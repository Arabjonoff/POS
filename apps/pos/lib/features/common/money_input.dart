import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Summa kiritish (butun so'm): katta raqam + ekran klaviaturasi (`00` bilan).
/// Fizik klaviatura: raqamlar, numpad, Backspace, Enter (`onSubmit`).
/// Qiymat tashqarida saqlanadi — tiyinda.
class MoneyInput extends StatefulWidget {
  const MoneyInput({
    required this.valueTiyin,
    required this.onChanged,
    this.onSubmit,
    this.autofocus = true,
    this.maxDigits = 10,
    super.key,
  });

  final int valueTiyin;
  final ValueChanged<int> onChanged;
  final VoidCallback? onSubmit;
  final bool autofocus;

  /// So'mdagi raqamlar soni chegarasi (10 — 9 999 999 999 so'm).
  final int maxDigits;

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  /// Oxirgi qiymat: bir kadr ichida bir nechta tugma kelsa ham raqam
  /// yo'qolmaydi (ota widget hali qayta chizilmagan bo'lishi mumkin).
  late int _value = widget.valueTiyin;

  @override
  void didUpdateWidget(MoneyInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valueTiyin != oldWidget.valueTiyin) _value = widget.valueTiyin;
  }

  int get _som => _value ~/ 100;

  void _set(int tiyin) {
    _value = tiyin;
    widget.onChanged(tiyin);
  }

  void _append(String digits) {
    final text = _som == 0 ? digits : '$_som$digits';
    final trimmed = text.replaceFirst(RegExp('^0+(?=.)'), '');
    if (trimmed.length > widget.maxDigits) return;
    _set(int.parse(trimmed) * 100);
  }

  void _backspace() => _set((_som ~/ 10) * 100);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final onSubmit = widget.onSubmit;
      if (onSubmit == null) return KeyEventResult.ignored;
      onSubmit();
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char != null && char.length == 1 && '0123456789'.contains(char)) {
      _append(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    return Focus(
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
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
                context.fmt.money(_value),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: PosTypography.h1.copyWith(
                  color: p.text,
                  fontFeatures: PosTypography.tabular,
                ),
              ),
            ),
          ),
          const SizedBox(height: PosSpacing.m),
          PosNumericKeypad(
            onKey: _append,
            onBackspace: _backspace,
            onClear: () => _set(0),
            backspaceTooltip: l10n.actionBackspace,
            extraKey: '00',
          ),
        ],
      ),
    );
  }
}
