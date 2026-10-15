import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/android_printer_channel.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/settings/settings_screen.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/fake_android_printer.dart';
import '../helpers/fake_printer.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

late AppDatabase _db;
late FakeAndroidPrinter native;

const PrinterSettings bluetooth = PrinterSettings(
  connection: PrinterConnection.bluetooth,
  address: '66:22:B3:01:9A:10',
  deviceName: 'XP-P323B',
);

/// Android kassa (T-047): haqiqiy transport, native tomoni — soxta kanal.
Future<void> open(WidgetTester tester, {PrinterSettings? settings}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  if (settings != null) {
    await _db.writeSetting(
      PrinterSettings.settingKey,
      jsonEncode(settings.toJson()),
    );
  }
  native = FakeAndroidPrinter()
    ..bluetooth = [
      {'id': '66:22:B3:01:9A:10', 'name': 'XP-P323B'},
      {'id': '00:11:22:33:44:55', 'name': 'MTP-II'},
    ]
    ..install();
  await pumpPosApp(
    tester,
    db: _db,
    size: const Size(390, 844),
    overrides: [androidPrintingProvider.overrideWithValue(true)],
  );
}

Future<void> sell(WidgetTester tester) async {
  await scanCode(tester, '4780000000014');
  await press(tester, LogicalKeyboardKey.f12);
  await press(tester, LogicalKeyboardKey.enter);
}

Future<void> openSettings(WidgetTester tester) async {
  await tapNav(tester, 'Sozlamalar');
  await tester.scrollUntilVisible(
    find.text('Ulanish'),
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

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<Map<String, Object?>> savedSettings() async =>
    jsonDecode((await _db.readSetting(PrinterSettings.settingKey))!)
        as Map<String, Object?>;

void main() {
  testWidgets('Bluetooth printer: sale receipt goes over the channel', (
    tester,
  ) async {
    await open(tester, settings: bluetooth);
    await sell(tester);
    final (method, device, bytes) = native.jobs.single;
    expect(method, 'bluetoothSend');
    expect(device, '66:22:B3:01:9A:10');
    expect(
      containsBytes(bytes, EscPos.encode('D3-000001', PrinterEncoding.cp866)),
      isTrue,
    );
    expect(find.text('Chek yopildi'), findsOneWidget);
  });

  testWidgets('Bluetooth printer off: the sale is kept, "not printed"', (
    tester,
  ) async {
    await open(tester, settings: bluetooth);
    native.sendError = 'io';
    await sell(tester);
    expect(await _db.select(_db.sales).get(), hasLength(1));
    expect(find.text('Chek yopildi — chop etilmadi'), findsOneWidget);
    expect(find.text('Qayta chop etish'), findsOneWidget);
  });

  testWidgets('settings: pick a paired Bluetooth printer from the list', (
    tester,
  ) async {
    await open(tester);
    await openSettings(tester);
    await tapVisible(tester, find.text('Bluetooth'));
    expect(find.text('XP-P323B'), findsOneWidget);
    await tapVisible(tester, find.text('MTP-II'));
    final saved = await savedSettings();
    expect(saved['connection'], 'bluetooth');
    expect(saved['address'], '00:11:22:33:44:55');
    expect(saved['device_name'], 'MTP-II');

    await tapVisible(tester, find.byKey(const ValueKey('printer-test')));
    expect(native.jobs.single.$2, '00:11:22:33:44:55');
    expect(find.text('Printerga yuborildi'), findsOneWidget);
  });

  testWidgets('settings: Bluetooth off and no permission are explained; '
      'refresh retries', (tester) async {
    await open(tester);
    native.listError = 'bluetooth_off';
    await openSettings(tester);
    await tapVisible(tester, find.text('Bluetooth'));
    expect(
      find.text("Bluetooth o'chiq — telefon sozlamalarida yoqing"),
      findsOneWidget,
    );

    native.listError = 'permission_denied';
    await tapVisible(tester, find.text("Ro'yxatni yangilash"));
    expect(find.text('Printerga ulanish uchun ruxsat bering'), findsOneWidget);

    native.listError = null;
    await tapVisible(tester, find.text("Ro'yxatni yangilash"));
    expect(find.text('XP-P323B'), findsOneWidget);
  });

  testWidgets('settings: no USB printer → how to connect; saved one stays', (
    tester,
  ) async {
    await open(
      tester,
      settings: const PrinterSettings(
        connection: PrinterConnection.usb,
        address: '1046:20497',
        deviceName: 'Xprinter XP-58',
      ),
    );
    await openSettings(tester);
    expect(find.text('USB printer topilmadi'), findsOneWidget);
    // Uzilgan printer tanlovdan yo'qolmaydi.
    expect(find.text('Xprinter XP-58'), findsOneWidget);
    expect(
      find.text('Hozir topilmadi — printerni yoqing yoki qayta ulang'),
      findsOneWidget,
    );

    native.usb = [
      {'id': '1046:20497', 'name': 'Xprinter XP-58'},
    ];
    await tapVisible(tester, find.text("Ro'yxatni yangilash"));
    expect(find.text('USB printer topilmadi'), findsNothing);
    expect(
      find.text('Hozir topilmadi — printerni yoqing yoki qayta ulang'),
      findsNothing,
    );
  });

  testWidgets('desktop (not Android): no Bluetooth/USB choice', (
    tester,
  ) async {
    _db = openTestDatabase();
    addTearDown(_db.close);
    await pumpPosApp(
      tester,
      db: _db,
      overrides: [androidPrintingProvider.overrideWithValue(false)],
    );
    await openSettings(tester);
    expect(find.text('Bluetooth'), findsNothing);
    expect(find.text('USB'), findsNothing);
  });
}
