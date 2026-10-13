import 'package:flutter/painting.dart';

/// Rang tokenlari — `docs/specs/design-system.md`. Kodda boshqa joyda rang yozilmaydi.
abstract final class PosColors {
  // Yorug' mavzu
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightPrimaryHover = Color(0xFF1D4ED8);
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightWarning = Color(0xFFD97706);
  static const Color lightDanger = Color(0xFFDC2626);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightMuted = Color(0xFF94A3B8);

  // Qorong'i mavzu
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkWarning = Color(0xFFF59E0B);
  static const Color darkDanger = Color(0xFFEF4444);
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkBorder = Color(0xFF1F2937);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkMuted = Color(0xFF64748B);
}
