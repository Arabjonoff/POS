import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/server_features.dart';
import 'package:pos_app/features/printing/android_printer_channel.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/settings/settings_screen.dart';

import '../helpers/fake_android_printer.dart';
import '../helpers/fake_printer.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

Future<void> _open(
  WidgetTester tester,
  Size size, {
  PaperWidth width = PaperWidth.mm80,
  PrinterConnection connection = PrinterConnection.network,
}) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  // Do'kon rekvizitlari va logotip (T-104b): oddiy geometrik belgi.
  final logo = GrayImage(
    160,
    60,
    Uint8List.fromList([
      for (var y = 0; y < 60; y++)
        for (var x = 0; x < 160; x++)
          (x - 30) * (x - 30) + (y - 30) * (y - 30) < 700 ||
                  (x > 70 && y > 18 && y < 42)
              ? 0
              : 255,
    ]),
  );
  await db
      .into(db.stores)
      .insert(
        StoresCompanion.insert(
          id: 'store-1',
          name: 'Baraka market',
          legalName: const Value('"Baraka" MChJ'),
          tin: const Value('123456789'),
          address: const Value('Chilonzor 7, 12-uy'),
          phone: const Value('+998712000000'),
          receiptFooter: const Value('Xaridingiz uchun rahmat!'),
          receiptLogo: Value(base64Encode(logo.toPng())),
        ),
      );
  await db.writeSetting(
    serverFeaturesSettingKey,
    encodeFeatures([ServerFeature.storeSettings]),
  );
  await db.writeSetting(
    PrinterSettings.settingKey,
    jsonEncode(
      PrinterSettings(
        connection: connection,
        address: connection == PrinterConnection.bluetooth
            ? '66:22:B3:01:9A:10'
            : '192.168.1.50',
        deviceName: connection == PrinterConnection.bluetooth ? 'XP-P323B' : '',
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
      androidPrintingProvider.overrideWithValue(
        connection == PrinterConnection.bluetooth,
      ),
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

  // T-047: Android — juftlangan Bluetooth printerlar ro'yxati.
  goldenAcrossDevices('printing', 'settings_bluetooth', (tester, size) async {
    FakeAndroidPrinter()
      ..bluetooth = [
        {'id': '66:22:B3:01:9A:10', 'name': 'XP-P323B'},
        {'id': '00:11:22:33:44:55', 'name': 'MTP-II'},
      ]
      ..install();
    await _open(tester, size, connection: PrinterConnection.bluetooth);
    await _scrollTo(tester, find.text('Ulanish'));
  });

  // T-104b: rekvizitlar formasi (o'ng/pastda — jonli chek).
  goldenAcrossDevices('printing', 'requisites', (tester, size) async {
    await _open(tester, size);
    await _scrollTo(tester, find.byKey(const ValueKey('store-name')));
  });
}
