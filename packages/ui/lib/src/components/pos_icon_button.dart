import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';

enum PosIconButtonVariant { standard, filled, tonal, outlined, danger }

/// Ikonli tugma. [tooltip] majburiy: ekran o'quvchi va sichqoncha uchun nom
/// (rang yoki ikon yolg'iz ma'no tashimaydi).
class PosIconButton extends StatelessWidget {
  const PosIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = PosIconButtonVariant.standard,
    this.size = PosSizes.touchMin,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(size >= PosSizes.touchMin, 'Bosish nishoni kamida 48 dp');

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final PosIconButtonVariant variant;

  /// Tomon uzunligi (dp), kamida 48.
  final double size;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final (bg, hover, fg, border) = switch (variant) {
      PosIconButtonVariant.standard => (
        Colors.transparent,
        p.surfaceMuted,
        p.textSecondary,
        null,
      ),
      PosIconButtonVariant.filled => (
        p.primary,
        p.primaryHover,
        p.onPrimary,
        null,
      ),
      PosIconButtonVariant.tonal => (
        p.surfaceMuted,
        p.border,
        p.text,
        null,
      ),
      PosIconButtonVariant.outlined => (
        p.surface,
        p.surfaceMuted,
        p.text,
        p.borderStrong,
      ),
      PosIconButtonVariant.danger => (
        Colors.transparent,
        p.dangerSoft,
        p.dangerText,
        null,
      ),
    };

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      focusNode: focusNode,
      autofocus: autofocus,
      icon: Icon(icon),
      iconSize: size >= PosSizes.cashierMain
          ? PosSizes.iconXl - 4
          : PosSizes.iconL,
      style: ButtonStyle(
        animationDuration: PosMotion.press,
        fixedSize: WidgetStatePropertyAll(Size.square(size)),
        minimumSize: WidgetStatePropertyAll(Size.square(size)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: PosRadius.controlAll),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: p.focus, width: 2);
          }
          return border == null ? null : BorderSide(color: border);
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return variant == PosIconButtonVariant.filled ? p.surfaceMuted : bg;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return hover;
          }
          return bg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? p.disabled : fg,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? fg.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
      ),
    );
  }
}
