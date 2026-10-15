import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// `dangerGhost` — matnli xavfli amal (masalan, "Qoralamani o'chirish"):
/// asosiy tugma yonida qizil, lekin fonsiz — e'tiborni tortib olmaydi.
/// `success` — yashil: yakunlovchi pul amali (kassada TO'LASH).
enum PosButtonVariant { primary, success, secondary, danger, ghost, dangerGhost }

/// Balandlik: s 48, m 56 (kassa asosiy), l 64, xl 80 (To'lash).
enum PosButtonSize {
  s(PosSizes.touchMin, PosSpacing.l, 14, PosSizes.iconM),
  m(PosSizes.cashierMain, PosSpacing.xl, 16, PosSizes.iconM),
  l(PosSizes.keypadKey, PosSpacing.xl, 18, PosSizes.iconL),
  xl(80, PosSpacing.xxl, 22, PosSizes.iconXl)
  ;

  const PosButtonSize(this.height, this.padding, this.fontSize, this.iconSize);

  final double height;
  final double padding;
  final double fontSize;
  final double iconSize;
}

/// Asosiy tugma. Ixtiyoriy [shortcut] (masalan, `F12`) tugmaning o'zida
/// yorliq sifatida ko'rinadi — klaviatura birinchi.
class PosButton extends StatelessWidget {
  const PosButton({
    required this.label,
    required this.onPressed,
    this.variant = PosButtonVariant.primary,
    this.size = PosButtonSize.m,
    this.icon,
    this.shortcut,
    this.loading = false,
    this.expand = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final String label;

  /// `null` — tugma o'chiq.
  final VoidCallback? onPressed;
  final PosButtonVariant variant;
  final PosButtonSize size;
  final IconData? icon;
  final String? shortcut;

  /// Jarayon ketyapti: spinner ko'rinadi, qayta bosish yutiladi.
  final bool loading;

  /// Butun kenglikni egallaydi.
  final bool expand;
  final FocusNode? focusNode;
  final bool autofocus;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final colors = _colors(p);
    final fg = _enabled ? colors.fg : colors.disabledFg;

    final iconWidget = loading
        ? SizedBox.square(
            dimension: size.iconSize - 2,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        : (icon == null ? null : Icon(icon, size: size.iconSize));

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconWidget != null) ...[
          iconWidget,
          const SizedBox(width: PosSpacing.s),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (shortcut != null) ...[
          const SizedBox(width: PosSpacing.s),
          PosKeycap(label: shortcut!, color: fg),
        ],
      ],
    );

    final button = TextButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      style: ButtonStyle(
        animationDuration: PosMotion.press,
        minimumSize: WidgetStatePropertyAll(Size(size.height, size.height)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: size.padding),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStatePropertyAll(
          PosTypography.label.copyWith(fontSize: size.fontSize),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: PosRadius.controlAll),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(
              color: p.focus,
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
            );
          }
          if (colors.border != null) {
            return BorderSide(
              color: _enabled ? colors.border! : p.border,
            );
          }
          return null;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return colors.disabledBg;
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return colors.hoverBg;
          }
          return colors.bg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.disabledFg
              : colors.fg,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? colors.fg.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
      ),
      child: content,
    );

    final guarded = loading
        ? IgnorePointer(child: ExcludeFocus(child: button))
        : button;

    return expand ? SizedBox(width: double.infinity, child: guarded) : guarded;
  }

  _ButtonColors _colors(PosPalette p) => switch (variant) {
    PosButtonVariant.primary => _ButtonColors(
      bg: p.primary,
      hoverBg: p.primaryHover,
      fg: p.onPrimary,
      disabledBg: p.surfaceMuted,
      disabledFg: p.disabled,
    ),
    PosButtonVariant.success => _ButtonColors(
      bg: p.success,
      hoverBg: Color.alphaBlend(
        p.text.withValues(alpha: p.brightness == Brightness.dark ? 0 : 0.12),
        p.success,
      ),
      fg: p.onSuccess,
      disabledBg: p.surfaceMuted,
      disabledFg: p.disabled,
    ),
    PosButtonVariant.secondary => _ButtonColors(
      bg: p.surface,
      hoverBg: p.surfaceMuted,
      fg: p.text,
      disabledBg: p.surface,
      disabledFg: p.disabled,
      border: p.borderStrong,
    ),
    PosButtonVariant.danger => _ButtonColors(
      bg: p.danger,
      hoverBg: p.dangerHover,
      fg: p.onDanger,
      disabledBg: p.surfaceMuted,
      disabledFg: p.disabled,
    ),
    PosButtonVariant.ghost => _ButtonColors(
      bg: Colors.transparent,
      hoverBg: p.primarySoft,
      fg: p.primaryText,
      disabledBg: Colors.transparent,
      disabledFg: p.disabled,
    ),
    PosButtonVariant.dangerGhost => _ButtonColors(
      bg: Colors.transparent,
      hoverBg: p.dangerSoft,
      fg: p.dangerText,
      disabledBg: Colors.transparent,
      disabledFg: p.disabled,
    ),
  };
}

final class _ButtonColors {
  const _ButtonColors({
    required this.bg,
    required this.hoverBg,
    required this.fg,
    required this.disabledBg,
    required this.disabledFg,
    this.border,
  });

  final Color bg;
  final Color hoverBg;
  final Color fg;
  final Color disabledBg;
  final Color disabledFg;
  final Color? border;
}

/// Klaviatura tugmasi yorlig'i: `F12`, `Esc`, `Enter`.
class PosKeycap extends StatelessWidget {
  const PosKeycap({required this.label, this.color, super.key});

  final String label;

  /// Matn va chegara rangi; `null` — ikkinchi darajali matn rangi.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? PosPalette.of(context).textSecondary;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          border: Border.all(color: c.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: PosTypography.caption.copyWith(
            color: c,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
