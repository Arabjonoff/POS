import 'package:flutter/services.dart';
import 'package:pos_app/app/status/app_status.dart';

import '../helpers/pump_app.dart';
import 'golden_helpers.dart';

/// Ilova qobig'i: kassa va sozlamalar.
void main() {
  for (final page in ['pos', 'settings']) {
    goldenAcrossDevices('app_shell', page, (tester, size) async {
      await pumpPosApp(
        tester,
        size: size,
        overrides: [
          connectionStatusProvider.overrideWithValue(ConnectionStatus.offline),
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
    });
  }
}
