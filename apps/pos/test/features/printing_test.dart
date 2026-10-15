import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/settings/settings_screen.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/fake_printer.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

late AppDatabase _db;
late FakeTransport printer;

const PrinterSettings network = PrinterSettings(
  connection: PrinterConnection.network,
  address: '192.168.1.50',
);

Future<void> open(
  WidgetTester tester, {
  PrinterSettings? settings = network,
  Size size = const Size(1440, 900),
}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  if (settings != null) {
    await _db.writeSetting(
      PrinterSettings.settingKey,
      jsonEncode(settings.toJson()),
    );
  }
  printer = FakeTransport();
  await pumpPosApp(
    tester,
    db: _db,
    size: size,
    overrides: [
      printerTransportFactoryProvider.overrideWithValue(
        (s) => s.configured ? printer : null,
      ),
      windowsPrintingProvider.overrideWithValue(true),
      systemPrintersProvider.overrideWithValue(const ['XP-80C', 'POS-58']),
    ],
  );
}

bool printed(List<int> job, String text) =>
    containsBytes(job, EscPos.encode(text, PrinterEncoding.cp866));

Future<void> sell(WidgetTester tester) async {
  await scanCode(tester, '4780000000014');
  await press(tester, LogicalKeyboardKey.f12);
  await press(tester, LogicalKeyboardKey.enter);
}

Future<Map<String, Object?>> savedSettings() async =>
    jsonDecode((await _db.readSetting(PrinterSettings.settingKey))!)
        as Map<String, Object?>;

void main() {
  testWidgets('sale → the receipt is printed automatically', (tester) async {
    await open(tester);
    await sell(tester);
    expect(printer.jobs, hasLength(1));
    expect(printed(printer.jobs.single, 'D3-000001'), isTrue);
    expect(printed(printer.jobs.single, 'NUSXA'), isFalse);
    expect(find.text('Chek yopildi'), findsOneWidget);
  });

  testWidgets('printer off: the sale stays, retry prints the original', (
    tester,
  ) async {
    await open(tester);
    printer.fail = true;
    await sell(tester);

    expect(await _db.select(_db.sales).get(), hasLength(1));
    expect(find.text('Chek yopildi — chop etilmadi'), findsOneWidget);
    expect(find.text('Printer ulanmagan'), findsOneWidget);

    printer.fail = false;
    await tester.tap(find.text('Qayta chop etish'));
    await tester.pumpAndSettle();
    expect(printer.jobs, hasLength(1));
    // Mijoz birinchi chekini oladi — "NUSXA" emas (audit PRN-B13).
    expect(printed(printer.jobs.single, 'NUSXA'), isFalse);
    expect(printed(printer.jobs.single, 'D3-000001'), isTrue);
    expect(find.text('Printer ulangan'), findsOneWidget);
  });

  testWidgets('auto print off: cash sale still opens the drawer', (
    tester,
  ) async {
    await open(
      tester,
      settings: network.copyWith(autoPrint: false, openDrawer: true),
    );
    await sell(tester);
    // Chek yo'q, faqat pul qutisi buyrug'i (audit PRN-B14).
    expect(printer.jobs.single, EscPos.drawerOnly());
  });

  testWidgets('auto print off → no receipt; "last receipt" prints it', (
    tester,
  ) async {
    await open(tester, settings: network.copyWith(autoPrint: false));
    await sell(tester);
    expect(printer.jobs, isEmpty);

    await tester.tap(find.byTooltip('Oxirgi chek'));
    await tester.pumpAndSettle();
    expect(printer.jobs, hasLength(1));
    expect(printed(printer.jobs.single, 'D3-000001'), isTrue);
    expect(printed(printer.jobs.single, 'NUSXA'), isTrue);
  });

  testWidgets('no printer: sale works, no reprint button', (tester) async {
    await open(tester, settings: null);
    expect(find.byTooltip('Oxirgi chek'), findsNothing);
    await sell(tester);
    expect(await _db.select(_db.sales).get(), hasLength(1));
    expect(find.text('Chek yopildi'), findsOneWidget);
    expect(find.text('Printer sozlanmagan'), findsOneWidget);
  });

  group('settings', () {
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

    testWidgets('network address is saved; test receipt is sent', (
      tester,
    ) async {
      await open(tester, settings: null);
      await openSettings(tester);
      await tapVisible(tester, find.text('Tarmoq (IP)'));
      await tester.enterText(
        find.byKey(const ValueKey('printer-address')),
        '192.168.1.77:9100',
      );
      // Manzil yozish to'xtagach saqlanadi (har harfda printer tekshirilmaydi).
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('80 mm'));
      await tapVisible(tester, find.text('2'));

      final saved = await savedSettings();
      expect(saved['connection'], 'network');
      expect(saved['address'], '192.168.1.77:9100');
      expect(saved['width'], 80);
      expect(saved['copies'], 2);

      await tapVisible(tester, find.byKey(const ValueKey('printer-test')));
      expect(printer.jobs, hasLength(1));
      expect(printed(printer.jobs.single, 'TEST CHEK'), isTrue);
      expect(find.text('Printerga yuborildi'), findsOneWidget);
    });

    testWidgets('windows printer is picked from the list', (tester) async {
      await open(tester, settings: null);
      await openSettings(tester);
      await tapVisible(tester, find.text('Kompyuter printeri'));
      await tapVisible(tester, find.text('XP-80C'));
      final saved = await savedSettings();
      expect(saved['connection'], 'windows');
      expect(saved['address'], 'XP-80C');
      // Pul qutisi: kalit.
      await tapVisible(tester, find.text("Naqd to'lovda pul qutisini ochish"));
      expect((await savedSettings())['open_drawer'], isTrue);
      expect(find.byType(PosEmptyState), findsNothing);
    });
  });
}
