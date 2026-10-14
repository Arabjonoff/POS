import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/app.dart';
import 'package:pos_app/app/status/app_status.dart';

import '../helpers/pump_app.dart';

/// Ilova qobig'i: telefon 390×844, planshet 1024×768, desktop 1440×900;
/// yorug' va qorong'i (CLAUDE.md, 5-band).
const Map<String, (Size, TargetPlatform)> devices = {
  'phone': (Size(390, 844), TargetPlatform.android),
  'tablet': (Size(1024, 768), TargetPlatform.android),
  'desktop': (Size(1440, 900), TargetPlatform.windows),
};

void main() {
  for (final MapEntry(key: device, value: (size, platform))
      in devices.entries) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';

      for (final page in ['pos', 'settings']) {
        testWidgets('$device $theme $page', (tester) async {
          debugDisableShadows = false;
          debugDefaultTargetPlatformOverride = platform;
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          try {
            await pumpPosApp(
              tester,
              size: size,
              overrides: [
                connectionStatusProvider.overrideWithValue(
                  ConnectionStatus.offline,
                ),
                printerStatusProvider.overrideWithValue(PrinterStatus.ready),
                pendingEventsProvider.overrideWith((ref) => Stream.value(12)),
                shiftOpenProvider.overrideWith((ref) => Stream.value(true)),
                clockProvider.overrideWithValue(
                  () => DateTime.utc(2026, 10, 14, 15, 15),
                ),
              ],
            );
            if (page == 'settings') {
              await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
              await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
              await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
              await tester.pumpAndSettle();
            }
            await expectLater(
              find.byType(PosApp),
              matchesGoldenFile('app_shell/${page}_${device}_$theme.png'),
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
}
