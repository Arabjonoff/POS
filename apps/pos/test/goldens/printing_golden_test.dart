import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/settings/settings_screen.dart';

import '../helpers/fake_printer.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

Future<void> _open(
  WidgetTester tester,
  Size size, {
  PaperWidth width = PaperWidth.mm80,
}) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  await db.writeSetting(
    PrinterSettings.settingKey,
    jsonEncode(
      PrinterSettings(
        connection: PrinterConnection.network,
        address: '192.168.1.50',
        width: width,
        copies: 2,
        openDrawer: true,
      ).toJson(),
    ),
  );
  await pumpPosApp(
    tester,
    size: size,
    db: db,
    overrides: [
      connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
      printerStatusProvider.overrideWithValue(PrinterStatus.ready),
      pendingEventsProvider.overrideWith((ref) => Stream.value(0)),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 15, 15)),
      printerTransportFactoryProvider.overrideWithValue(
        (_) => FakeTransport(),
      ),
      windowsPrintingProvider.overrideWithValue(true),
      systemPrintersProvider.overrideWithValue(const ['XP-80C']),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// Sozlamalar → Chek printeri (tarmoq, 80 mm, 2 nusxa, pul qutisi) va chek
/// ko'rinishi (namuna: uzun nom, vaznli tovar, chegirma, aralash to'lov).
void main() {
  goldenAcrossDevices('printing', 'settings', (tester, size) async {
    await _open(tester, size);
    await _scrollTo(tester, find.text('Ulanish'));
  });

  goldenAcrossDevices('printing', 'preview_80', (tester, size) async {
    await _open(tester, size);
    await _scrollTo(tester, find.byKey(const ValueKey('receipt-preview')));
  });

  goldenAcrossDevices('printing', 'preview_58', (tester, size) async {
    await _open(tester, size, width: PaperWidth.mm58);
    await _scrollTo(tester, find.byKey(const ValueKey('receipt-preview')));
  });
}
