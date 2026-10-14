import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/app.dart';

/// Golden o'lchamlari: telefon, planshet, desktop (CLAUDE.md, 5-band).
const Map<String, (Size, TargetPlatform)> goldenDevices = {
  'phone': (Size(390, 844), TargetPlatform.android),
  'tablet': (Size(1024, 768), TargetPlatform.android),
  'desktop': (Size(1440, 900), TargetPlatform.windows),
};

/// Har o'lcham × yorug'/qorong'i uchun test: [body] ilovani ochadi va
/// kerakli holatga keltiradi, keyin `<dir>/<name>_<device>_<theme>.png`.
void goldenAcrossDevices(
  String dir,
  String name,
  Future<void> Function(WidgetTester tester, Size size) body,
) {
  for (final MapEntry(key: device, value: (size, platform))
      in goldenDevices.entries) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('$name $device $theme', (tester) async {
        debugDisableShadows = false;
        debugDefaultTargetPlatformOverride = platform;
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        try {
          await body(tester, size);
          await expectLater(
            find.byType(PosApp),
            matchesGoldenFile('$dir/${name}_${device}_$theme.png'),
          );
        } finally {
          debugDisableShadows = true;
          debugDefaultTargetPlatformOverride = null;
          tester.platformDispatcher.clearPlatformBrightnessTestValue();
        }
      });
    }
  }
}
