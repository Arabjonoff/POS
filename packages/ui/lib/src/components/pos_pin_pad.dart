import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_ui/src/components/pos_numeric_keypad.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// PIN kiritish: nuqtalar + katta raqamli klaviatura. Fizik klaviaturadagi
/// raqamlar va Backspace ham ishlaydi (fokus shu vidjetda bo'lsa).
///
/// Holat tashqarida saqlanadi: [filled] — kiritilgan raqamlar soni.
/// PIN uzunligi o'zgaruvchan bo'lsa (4–6) — [onSubmit] (✓ tugma va Enter);
/// nuqtalar soni `max(length, filled)`.
class PosPinPad extends StatelessWidget {
  const PosPinPad({
    required this.filled,
    required this.onDigit,
    required this.onBackspace,
    required this.backspaceTooltip,
    this.length = 4,
    this.maxLength = 6,
    this.onSubmit,
    this.submitTooltip,
    this.errorText,
    this.enabled = true,
    this.autofocus = true,
    this.focusNode,
    super.key,
  }) : assert(filled >= 0 && filled <= maxLength, 'filled 0..maxLength'),
       assert(length <= maxLength, 'length <= maxLength');

  final int filled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String backspaceTooltip;

  /// Kamida shuncha nuqta ko'rinadi.
  final int length;
  final int maxLength;

  /// Tasdiqlash (✓ tugma, Enter). `null` — tugma yo'q.
  final VoidCallback? onSubmit;
  final String? submitTooltip;

  /// Xato (noto'g'ri PIN, kutish vaqti) — nuqtalar qizil, ostida matn.
  final String? errorText;

  /// `false` — masalan, 5 marta xatodan keyin kutish paytida.
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      onBackspace();
      return KeyEventResult.handled;
    }
    if (onSubmit != null &&
        (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter)) {
      onSubmit!();
      return KeyEventResult.handled;
    }
    final digit = _digitKeys[key];
    if (digit != null) {
      onDigit(digit);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static final Map<LogicalKeyboardKey, String> _digitKeys = {
    LogicalKeyboardKey.digit0: '0',
    LogicalKeyboardKey.digit1: '1',
    LogicalKeyboardKey.digit2: '2',
    LogicalKeyboardKey.digit3: '3',
    LogicalKeyboardKey.digit4: '4',
    LogicalKeyboardKey.digit5: '5',
    LogicalKeyboardKey.digit6: '6',
    LogicalKeyboardKey.digit7: '7',
    LogicalKeyboardKey.digit8: '8',
    LogicalKeyboardKey.digit9: '9',
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
  };

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onKeyEvent: _onKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: '$filled',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < (filled > length ? filled : length); i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PosSpacing.s,
                      ),
                      child: AnimatedContainer(
                        duration: PosMotion.press,
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < filled
                              ? (hasError ? p.danger : p.text)
                              : Colors.transparent,
                          border: Border.all(
                            color: hasError ? p.danger : p.borderStrong,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: PosSpacing.xxxl,
              child: Center(
                child: hasError
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: PosSizes.iconM,
                            color: p.dangerText,
                          ),
                          const SizedBox(width: PosSpacing.s),
                          Flexible(
                            child: Text(
                              errorText!,
                              textAlign: TextAlign.center,
                              style: PosTypography.small.copyWith(
                                color: p.dangerText,
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            PosNumericKeypad(
              onSubmit: onSubmit,
              submitTooltip: submitTooltip,
              onKey: onDigit,
              onBackspace: onBackspace,
              backspaceTooltip: backspaceTooltip,
              keyHeight: 72,
              gap: PosSpacing.m,
              enabled: enabled,
            ),
          ],
        ),
      ),
    );
  }
}
