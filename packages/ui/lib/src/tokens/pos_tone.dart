import 'package:flutter/painting.dart';

/// Semantik ohang: badge, holat nuqtasi, toast, summa rangi uchun.
enum PosTone { neutral, primary, success, warning, danger }

/// Bitta ohangning ranglar to'plami.
///
/// [fill] — to'liq bo'yalgan fon, [onFill] — undagi matn; [text] — sirt
/// (surface/background) ustidagi matn yoki ikon; [soft] — yumshoq fon,
/// [onSoft] — undagi matn. Barcha juftliklar WCAG AA (≥ 4,5:1).
final class PosToneColors {
  const PosToneColors({
    required this.fill,
    required this.onFill,
    required this.text,
    required this.soft,
    required this.onSoft,
  });

  final Color fill;
  final Color onFill;
  final Color text;
  final Color soft;
  final Color onSoft;
}
