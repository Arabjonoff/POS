import 'package:flutter/material.dart';
import 'package:pos_ui/src/theme/pos_colors.dart';

/// Ilovaning yorug' va qorong'i mavzulari. To'liq komponent mavzulari T-030 da.
abstract final class PosTheme {
  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: PosColors.lightPrimary,
      onPrimary: PosColors.lightSurface,
      secondary: PosColors.lightTextSecondary,
      onSecondary: PosColors.lightSurface,
      error: PosColors.lightDanger,
      onError: PosColors.lightSurface,
      surface: PosColors.lightSurface,
      onSurface: PosColors.lightText,
      onSurfaceVariant: PosColors.lightTextSecondary,
      outline: PosColors.lightBorder,
      outlineVariant: PosColors.lightBorder,
    ),
    background: PosColors.lightBackground,
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: PosColors.darkPrimary,
      onPrimary: PosColors.darkBackground,
      secondary: PosColors.darkTextSecondary,
      onSecondary: PosColors.darkBackground,
      error: PosColors.darkDanger,
      onError: PosColors.darkBackground,
      surface: PosColors.darkSurface,
      onSurface: PosColors.darkText,
      onSurfaceVariant: PosColors.darkTextSecondary,
      outline: PosColors.darkBorder,
      outlineVariant: PosColors.darkBorder,
    ),
    background: PosColors.darkBackground,
  );

  static ThemeData _build(ColorScheme scheme, {required Color background}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
