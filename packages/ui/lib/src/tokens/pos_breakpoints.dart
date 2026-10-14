import 'package:flutter/widgets.dart';

/// Ekran o'lchami sinfi: compact < 600 (telefon), medium 600–899,
/// expanded ≥ 900 (planshet/desktop), large ≥ 1280 (desktop).
enum PosWindowSize {
  compact,
  medium,
  expanded,
  large
  ;

  static const double mediumMin = 600;
  static const double expandedMin = 900;
  static const double largeMin = 1280;

  static PosWindowSize fromWidth(double width) {
    if (width >= largeMin) return large;
    if (width >= expandedMin) return expanded;
    if (width >= mediumMin) return medium;
    return compact;
  }

  static PosWindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == compact;

  /// Planshet yoki desktop: chapda navigatsiya, yonma-yon panellar.
  bool get isExpandedUp => index >= expanded.index;
}
