import 'package:flutter/painting.dart';

/// Tipografiya: Inter (lotin + kirill). Rang yo'q — rang mavzudan
/// (`DefaultTextStyle`) yoki `PosPalette` dan olinadi.
///
/// O'lchamlar: display 48/40/32 (jami summa: desktop/planshet/telefon),
/// h1 28, h2 22, h3 18, body 16, small 14, caption 12.
abstract final class PosTypography {
  static const String fontFamily = 'Inter';
  static const String fontPackage = 'pos_ui';

  /// Ro'yxatdan o'tgan to'liq oila nomi (paket shrifti).
  static const String fontFamilyName = 'packages/$fontPackage/$fontFamily';

  /// Raqamlar bir xil kenglikda — summa va miqdor ustunlari tekis turadi.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 48,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    fontFeatures: tabular,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 40,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    fontFeatures: tabular,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    fontFeatures: tabular,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 28,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle small = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle smallStrong = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// Chek ko'rinishi (preview): monospace — printer ustunlari ekranda ham
  /// tekis. O'lcham ko'rinish kengligiga qarab moslashtiriladi.
  static const TextStyle receipt = TextStyle(
    fontFamily: 'RobotoMono',
    package: fontPackage,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );

  /// Tugma yozuvi (o'lchamga qarab `fontSize` almashtiriladi).
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );
}
