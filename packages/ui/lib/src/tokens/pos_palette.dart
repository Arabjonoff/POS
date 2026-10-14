import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_colors.dart';
import 'package:pos_ui/src/tokens/pos_tone.dart';

/// Semantik ranglar va soyalar (yorug'/qorong'i). `ThemeData.extensions` da
/// yuradi; komponentlar ranglarni faqat shu yerdan oladi.
///
/// Spec'dagi boshlang'ich ranglardan farqi (WCAG AA uchun): oq matnli
/// success/warning tugmalari `#15803D`/`#B45309`; qorong'i mavzuda
/// to'ldirilgan primary `#2563EB` (oq matn 5,2:1), matn sifatida `#60A5FA`.
@immutable
class PosPalette extends ThemeExtension<PosPalette> {
  const PosPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.disabled,
    required this.primary,
    required this.onPrimary,
    required this.primaryHover,
    required this.primaryText,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.success,
    required this.onSuccess,
    required this.successText,
    required this.successSoft,
    required this.onSuccessSoft,
    required this.warning,
    required this.onWarning,
    required this.warningText,
    required this.warningSoft,
    required this.onWarningSoft,
    required this.danger,
    required this.onDanger,
    required this.dangerHover,
    required this.dangerText,
    required this.dangerSoft,
    required this.onDangerSoft,
    required this.neutralSoft,
    required this.onNeutralSoft,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
    required this.focus,
    required this.scrim,
    required this.cardShadow,
    required this.overlayShadow,
  });

  static const PosPalette light = PosPalette(
    brightness: Brightness.light,
    background: PosColors.slate50,
    surface: PosColors.white,
    surfaceMuted: PosColors.slate100,
    border: PosColors.slate200,
    borderStrong: PosColors.slate300,
    text: PosColors.slate900,
    textSecondary: PosColors.slate600,
    textMuted: PosColors.slate500,
    disabled: PosColors.slate400,
    primary: PosColors.blue600,
    onPrimary: PosColors.white,
    primaryHover: PosColors.blue700,
    primaryText: PosColors.blue600,
    primarySoft: PosColors.blue100,
    onPrimarySoft: PosColors.blue700,
    success: PosColors.green700,
    onSuccess: PosColors.white,
    successText: PosColors.green700,
    successSoft: PosColors.green100,
    onSuccessSoft: PosColors.green800,
    warning: PosColors.amber700,
    onWarning: PosColors.white,
    warningText: PosColors.amber700,
    warningSoft: PosColors.amber100,
    onWarningSoft: PosColors.amber800,
    danger: PosColors.red600,
    onDanger: PosColors.white,
    dangerHover: PosColors.red700,
    dangerText: PosColors.red600,
    dangerSoft: PosColors.red100,
    onDangerSoft: PosColors.red700,
    neutralSoft: PosColors.slate100,
    onNeutralSoft: PosColors.slate700,
    inverseSurface: PosColors.slate900,
    onInverseSurface: PosColors.slate100,
    inversePrimary: PosColors.blue300,
    focus: PosColors.blue600,
    scrim: Color(0x800F172A),
    cardShadow: [
      BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 1), blurRadius: 3),
      BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 2),
    ],
    overlayShadow: [
      BoxShadow(
        color: Color(0x1F0F172A),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
      BoxShadow(color: Color(0x140F172A), offset: Offset(0, 4), blurRadius: 8),
    ],
  );

  static const PosPalette dark = PosPalette(
    brightness: Brightness.dark,
    background: PosColors.night950,
    surface: PosColors.night900,
    surfaceMuted: PosColors.night800,
    border: PosColors.night800,
    borderStrong: PosColors.night700,
    text: PosColors.slate100,
    textSecondary: PosColors.slate300,
    textMuted: PosColors.slate400,
    disabled: PosColors.slate500,
    primary: PosColors.blue600,
    onPrimary: PosColors.white,
    primaryHover: PosColors.blue700,
    primaryText: PosColors.blue400,
    primarySoft: PosColors.blue950,
    onPrimarySoft: PosColors.blue300,
    success: PosColors.green700,
    onSuccess: PosColors.white,
    successText: PosColors.green500,
    successSoft: PosColors.green900,
    onSuccessSoft: PosColors.green400,
    warning: PosColors.amber700,
    onWarning: PosColors.white,
    warningText: PosColors.amber500,
    warningSoft: PosColors.amber950,
    onWarningSoft: PosColors.amber400,
    danger: PosColors.red600,
    onDanger: PosColors.white,
    dangerHover: PosColors.red700,
    dangerText: PosColors.red400,
    dangerSoft: PosColors.red950,
    onDangerSoft: PosColors.red300,
    neutralSoft: PosColors.night800,
    onNeutralSoft: PosColors.slate300,
    inverseSurface: PosColors.slate100,
    onInverseSurface: PosColors.slate900,
    inversePrimary: PosColors.blue700,
    focus: PosColors.blue400,
    scrim: Color(0x99000000),
    cardShadow: [],
    overlayShadow: [
      BoxShadow(
        color: Color(0x80000000),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
  );

  /// Joriy mavzu palitrasi. Mavzuda bo'lmasa — yorug'/qorong'i bo'yicha standart.
  static PosPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PosPalette>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color disabled;
  final Color primary;
  final Color onPrimary;
  final Color primaryHover;
  final Color primaryText;
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color success;
  final Color onSuccess;
  final Color successText;
  final Color successSoft;
  final Color onSuccessSoft;
  final Color warning;
  final Color onWarning;
  final Color warningText;
  final Color warningSoft;
  final Color onWarningSoft;
  final Color danger;
  final Color onDanger;
  final Color dangerHover;
  final Color dangerText;
  final Color dangerSoft;
  final Color onDangerSoft;
  final Color neutralSoft;
  final Color onNeutralSoft;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;
  final Color focus;
  final Color scrim;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> overlayShadow;

  /// Ohang bo'yicha ranglar to'plami.
  PosToneColors tone(PosTone tone) => switch (tone) {
    PosTone.neutral => PosToneColors(
      fill: text,
      onFill: surface,
      text: textSecondary,
      soft: neutralSoft,
      onSoft: onNeutralSoft,
    ),
    PosTone.primary => PosToneColors(
      fill: primary,
      onFill: onPrimary,
      text: primaryText,
      soft: primarySoft,
      onSoft: onPrimarySoft,
    ),
    PosTone.success => PosToneColors(
      fill: success,
      onFill: onSuccess,
      text: successText,
      soft: successSoft,
      onSoft: onSuccessSoft,
    ),
    PosTone.warning => PosToneColors(
      fill: warning,
      onFill: onWarning,
      text: warningText,
      soft: warningSoft,
      onSoft: onWarningSoft,
    ),
    PosTone.danger => PosToneColors(
      fill: danger,
      onFill: onDanger,
      text: dangerText,
      soft: dangerSoft,
      onSoft: onDangerSoft,
    ),
  };

  @override
  PosPalette copyWith() => this;

  @override
  PosPalette lerp(PosPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PosPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      disabled: c(disabled, other.disabled),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryHover: c(primaryHover, other.primaryHover),
      primaryText: c(primaryText, other.primaryText),
      primarySoft: c(primarySoft, other.primarySoft),
      onPrimarySoft: c(onPrimarySoft, other.onPrimarySoft),
      success: c(success, other.success),
      onSuccess: c(onSuccess, other.onSuccess),
      successText: c(successText, other.successText),
      successSoft: c(successSoft, other.successSoft),
      onSuccessSoft: c(onSuccessSoft, other.onSuccessSoft),
      warning: c(warning, other.warning),
      onWarning: c(onWarning, other.onWarning),
      warningText: c(warningText, other.warningText),
      warningSoft: c(warningSoft, other.warningSoft),
      onWarningSoft: c(onWarningSoft, other.onWarningSoft),
      danger: c(danger, other.danger),
      onDanger: c(onDanger, other.onDanger),
      dangerHover: c(dangerHover, other.dangerHover),
      dangerText: c(dangerText, other.dangerText),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      onDangerSoft: c(onDangerSoft, other.onDangerSoft),
      neutralSoft: c(neutralSoft, other.neutralSoft),
      onNeutralSoft: c(onNeutralSoft, other.onNeutralSoft),
      inverseSurface: c(inverseSurface, other.inverseSurface),
      onInverseSurface: c(onInverseSurface, other.onInverseSurface),
      inversePrimary: c(inversePrimary, other.inversePrimary),
      focus: c(focus, other.focus),
      scrim: c(scrim, other.scrim),
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? [],
      overlayShadow:
          BoxShadow.lerpList(overlayShadow, other.overlayShadow, t) ?? [],
    );
  }
}
