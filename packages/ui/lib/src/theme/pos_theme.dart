import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Ilovaning yorug' va qorong'i mavzulari. Material komponentlari ham
/// tokenlar bilan bezatilgan — ekranlar to'g'ridan-to'g'ri Material
/// vidjetini ishlatsa ham ko'rinish bir xil bo'ladi.
abstract final class PosTheme {
  static ThemeData light({TargetPlatform? platform}) =>
      build(PosPalette.light, platform: platform);

  static ThemeData dark({TargetPlatform? platform}) =>
      build(PosPalette.dark, platform: platform);

  static ThemeData build(PosPalette p, {TargetPlatform? platform}) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primarySoft,
      onPrimaryContainer: p.onPrimarySoft,
      secondary: p.textSecondary,
      onSecondary: p.surface,
      secondaryContainer: p.neutralSoft,
      onSecondaryContainer: p.onNeutralSoft,
      tertiary: p.success,
      onTertiary: p.onSuccess,
      error: p.danger,
      onError: p.onDanger,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.onDangerSoft,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceMuted,
      surfaceTint: Colors.transparent,
      outline: p.borderStrong,
      outlineVariant: p.border,
      inverseSurface: p.inverseSurface,
      onInverseSurface: p.onInverseSurface,
      inversePrimary: p.inversePrimary,
      shadow: p.scrim,
      scrim: p.scrim,
    );

    final textTheme = const TextTheme(
      displayLarge: PosTypography.displayLarge,
      displayMedium: PosTypography.displayMedium,
      displaySmall: PosTypography.displaySmall,
      headlineLarge: PosTypography.h1,
      headlineMedium: PosTypography.h1,
      headlineSmall: PosTypography.h2,
      titleLarge: PosTypography.h2,
      titleMedium: PosTypography.h3,
      titleSmall: PosTypography.bodyStrong,
      bodyLarge: PosTypography.body,
      bodyMedium: PosTypography.body,
      bodySmall: PosTypography.small,
      labelLarge: PosTypography.label,
      labelMedium: PosTypography.smallStrong,
      labelSmall: PosTypography.caption,
    ).apply(bodyColor: p.text, displayColor: p.text);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: PosRadius.inputAll,
          borderSide: BorderSide(color: color, width: width),
        );

    const controlShape = RoundedRectangleBorder(
      borderRadius: PosRadius.controlAll,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      platform: platform,
      colorScheme: scheme,
      fontFamily: PosTypography.fontFamilyName,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.surface,
      dividerColor: p.border,
      disabledColor: p.disabled,
      hintColor: p.textMuted,
      focusColor: p.primary.withValues(alpha: 0.12),
      hoverColor: p.text.withValues(alpha: 0.04),
      highlightColor: Colors.transparent,
      splashColor: p.text.withValues(alpha: 0.08),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [p],
      iconTheme: IconThemeData(color: p.textSecondary, size: PosSizes.iconL),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.24),
        selectionHandleColor: p.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hoverColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PosSpacing.m,
          vertical: PosSpacing.m,
        ),
        constraints: const BoxConstraints(minHeight: PosSizes.touchMin),
        hintStyle: PosTypography.body.copyWith(color: p.textMuted),
        labelStyle: PosTypography.body.copyWith(color: p.textSecondary),
        helperStyle: PosTypography.small.copyWith(color: p.textSecondary),
        errorStyle: PosTypography.small.copyWith(color: p.dangerText),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        border: inputBorder(p.borderStrong),
        enabledBorder: inputBorder(p.borderStrong),
        focusedBorder: inputBorder(p.focus, 2),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 2),
        disabledBorder: inputBorder(p.border),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.disabled,
          minimumSize: const Size(PosSizes.touchMin, PosSizes.touchMin),
          shape: controlShape,
          textStyle: PosTypography.label,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(PosSizes.touchMin, PosSizes.touchMin),
          elevation: 0,
          shape: controlShape,
          textStyle: PosTypography.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.borderStrong),
          minimumSize: const Size(PosSizes.touchMin, PosSizes.touchMin),
          shape: controlShape,
          textStyle: PosTypography.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primaryText,
          minimumSize: const Size(PosSizes.touchMin, PosSizes.touchMin),
          shape: controlShape,
          textStyle: PosTypography.label,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textSecondary,
          minimumSize: const Size(PosSizes.touchMin, PosSizes.touchMin),
          shape: controlShape,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
          side: BorderSide(color: p.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: PosRadius.overlayAll,
        ),
        titleTextStyle: PosTypography.h2.copyWith(color: p.text),
        contentTextStyle: PosTypography.body.copyWith(color: p.textSecondary),
        barrierColor: p.scrim,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: p.scrim,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(PosRadius.overlay),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.inverseSurface,
        contentTextStyle: PosTypography.body.copyWith(
          color: p.onInverseSurface,
        ),
        actionTextColor: p.inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.inverseSurface,
          borderRadius: PosRadius.inputAll,
        ),
        textStyle: PosTypography.small.copyWith(color: p.onInverseSurface),
        waitDuration: const Duration(milliseconds: 500),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.text,
        selectedColor: p.onPrimarySoft,
        selectedTileColor: p.primarySoft,
        minVerticalPadding: PosSpacing.s,
        shape: const RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primarySoft,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => PosTypography.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? p.onPrimarySoft
                : p.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? p.onPrimarySoft
                : p.textSecondary,
            size: PosSizes.iconL,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceMuted,
        circularTrackColor: Colors.transparent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          p.textMuted.withValues(alpha: 0.5),
        ),
        radius: const Radius.circular(PosRadius.pill),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        side: BorderSide(color: p.borderStrong, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(p.borderStrong),
      ),
    );
  }
}
