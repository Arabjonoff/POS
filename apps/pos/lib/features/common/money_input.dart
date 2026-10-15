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
    this.pristine = false,
    this.hardwareDigits = true,
    this.showKeypad = true,
    this.onDisplayTap,
    this.keypadSide,
    this.below = const [],
    super.key,
  });

  final int valueTiyin;
  final ValueChanged<int> onChanged;
  final VoidCallback? onSubmit;
  final bool autofocus;

  /// So'mdagi raqamlar soni chegarasi (10 — 9 999 999 999 so'm).
  final int maxDigits;

  /// Ko'rsatilgan qiymat taklif (masalan, to'lovda "Aniq" summa): birinchi
  /// raqam uni almashtiradi, Backspace — nolga tushiradi.
  final bool pristine;

  /// `false` — fizik klaviatura raqamlarini bu maydon o'zi olmaydi (ekran
  /// ularni skaner xizmatining `onTyping` i orqali [append] bilan beradi,
  /// aks holda skaner raqamlari ham summaga tushadi). Backspace va Enter —
  /// baribir shu yerda.
  final bool hardwareDigits;

  /// `false` — faqat summa (telefonda joy tejash); [onDisplayTap] bilan
  /// ekran klaviaturani ochadi.
  final bool showKeypad;
  final VoidCallback? onDisplayTap;

  /// Keng oyna: raqamlar paneli o'ngda shu kenglikda, [below] — displey
  /// ostida (chap ustunda; masalan, qaytim). `null` — panel displey ostida.
  final double? keypadSide;
  final List<Widget> below;

  /// [valueTiyin] oxiriga so'm raqamlarini qo'shadi (raqam bo'lmaganlar
  /// tashlanadi; [maxDigits] dan oshsa — o'zgarmaydi). Ekran klaviaturani
  /// o'zi ushlaganda (skaner xizmati `onTyping`) ham shu qoida.
  static int append(int valueTiyin, String digits, {int maxDigits = 10}) {
    final clean = digits.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return valueTiyin;
    final som = valueTiyin ~/ 100;
    final text = (som == 0 ? clean : '$som$clean').replaceFirst(
      RegExp('^0+(?=.)'),
      '',
    );
    if (text.length > maxDigits) return valueTiyin;
    return int.parse(text) * 100;
  }

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  /// Oxirgi qiymat: bir kadr ichida bir nechta tugma kelsa ham raqam
  /// yo'qolmaydi (ota widget hali qayta chizilmagan bo'lishi mumkin).
  late int _value = widget.valueTiyin;
  late bool _pristine = widget.pristine;

  @override
  void didUpdateWidget(MoneyInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valueTiyin != oldWidget.valueTiyin) _value = widget.valueTiyin;
    if (widget.pristine != oldWidget.pristine) _pristine = widget.pristine;
  }

  int get _som => _value ~/ 100;

  void _set(int tiyin) {
    _value = tiyin;
    _pristine = false;
    widget.onChanged(tiyin);
  }

  void _append(String digits) {
    final base = _pristine ? 0 : _value;
    final next = MoneyInput.append(base, digits, maxDigits: widget.maxDigits);
    if (next != _value || _pristine) _set(next);
  }

  void _backspace() => _set(_pristine ? 0 : (_som ~/ 10) * 100);

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
    if (widget.hardwareDigits &&
        char != null &&
        char.length == 1 &&
        '0123456789'.contains(char)) {
      _append(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final keypad = PosNumericKeypad(
      onKey: _append,
      onBackspace: _backspace,
      onClear: () => _set(0),
      backspaceTooltip: l10n.actionBackspace,
      extraKey: '00',
    );
    final display = GestureDetector(
      onTap: widget.onDisplayTap,
      child: Container(
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
    );
    final side = widget.keypadSide;
    return Focus(
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: side != null && widget.showKeypad
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [display, ...widget.below],
                  ),
                ),
                const SizedBox(width: PosSpacing.l),
                SizedBox(width: side, child: keypad),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                display,
                if (widget.showKeypad) ...[
                  const SizedBox(height: PosSpacing.m),
                  keypad,
                ],
                ...widget.below,
              ],
            ),
    );
  }
}
