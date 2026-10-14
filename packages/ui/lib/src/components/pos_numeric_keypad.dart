import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Ekrandagi raqamli klaviatura (sensorli ekran uchun): 1–9, pastki qatorda
/// [extraKey] (`00` yoki `,`), 0 va o'chirish. Tugmalar kamida 64 dp.
///
/// Fizik klaviatura bilan ishlash — ekranning o'zida (bu vidjet fokus olmaydi).
class PosNumericKeypad extends StatelessWidget {
  const PosNumericKeypad({
    required this.onKey,
    required this.onBackspace,
    required this.backspaceTooltip,
    this.extraKey,
    this.onClear,
    this.keyHeight = PosSizes.keypadKey,
    this.gap = PosSpacing.s,
    this.enabled = true,
    super.key,
  }) : assert(keyHeight >= PosSizes.keypadKey, 'Tugma kamida 64 dp');

  /// Raqam yoki [extraKey] matni bosildi.
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  /// O'chirish tugmasining nomi (tarjimadan).
  final String backspaceTooltip;

  /// Pastki chap tugma: `00`, `,` yoki `null` (bo'sh joy).
  final String? extraKey;

  /// O'chirish tugmasini uzoq bosish — hammasini tozalash.
  final VoidCallback? onClear;
  final double keyHeight;
  final double gap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => _KeypadKey(
      height: keyHeight,
      onTap: enabled ? () => onKey(d) : null,
      child: Text(d),
    );

    Widget row(List<Widget> keys) => Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: keys[i]),
        ],
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        SizedBox(height: gap),
        row([digit('4'), digit('5'), digit('6')]),
        SizedBox(height: gap),
        row([digit('7'), digit('8'), digit('9')]),
        SizedBox(height: gap),
        row([
          if (extraKey == null)
            SizedBox(height: keyHeight)
          else
            digit(extraKey!),
          digit('0'),
          _KeypadKey(
            height: keyHeight,
            tooltip: backspaceTooltip,
            onTap: enabled ? onBackspace : null,
            onLongPress: enabled ? onClear : null,
            muted: true,
            child: const Icon(Icons.backspace_outlined),
          ),
        ]),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.height,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.tooltip,
    this.muted = false,
  });

  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final String? tooltip;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final fg = onTap == null ? p.disabled : p.text;
    Widget key = Material(
      color: muted ? p.surfaceMuted : p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: PosRadius.controlAll,
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        canRequestFocus: false,
        splashColor: p.primary.withValues(alpha: 0.12),
        hoverColor: p.text.withValues(alpha: 0.04),
        child: SizedBox(
          height: height,
          child: Center(
            child: DefaultTextStyle.merge(
              style: PosTypography.h1.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                fontFeatures: PosTypography.tabular,
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: fg, size: PosSizes.iconXl - 4),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      key = Tooltip(message: tooltip, excludeFromSemantics: true, child: key);
      key = Semantics(label: tooltip, button: true, child: key);
    }
    return key;
  }
}
