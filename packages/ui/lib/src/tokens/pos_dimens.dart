import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Oraliqlar (dp): 4, 8, 12, 16, 24, 32, 48.
abstract final class PosSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Burchak radiuslari: input 8, tugma/karta 12, oyna 16, badge 999.
abstract final class PosRadius {
  static const double input = 8;
  static const double control = 12;
  static const double overlay = 16;
  static const double pill = 999;

  static const BorderRadius inputAll = BorderRadius.all(Radius.circular(input));
  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius overlayAll = BorderRadius.all(
    Radius.circular(overlay),
  );
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Bosiladigan nishonlar va komponent o'lchamlari (dp).
abstract final class PosSizes {
  /// Har qanday bosiladigan element — kamida 48.
  static const double touchMin = 48;

  /// Kassa asosiy tugmalari — kamida 56.
  static const double cashierMain = 56;

  /// Raqamli klaviatura tugmasi — kamida 64.
  static const double keypadKey = 64;

  static const double iconS = 16;
  static const double iconM = 20;
  static const double iconL = 24;
  static const double iconXl = 32;

  /// Desktop yon navigatsiya kengligi.
  static const double sideNavWidth = 240;

  /// Planshet navigatsiya relsi kengligi.
  static const double railWidth = 88;

  /// Oyna (dialog) standart maksimal kengligi.
  static const double dialogMaxWidth = 480;

  /// Holat qatori balandligi.
  static const double statusBarHeight = 40;
}

/// Harakat: bosish 120 ms, oyna 200 ms. Animatsiya 200 ms dan oshmaydi.
abstract final class PosMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration overlay = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;
}
