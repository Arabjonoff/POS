import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/shift/cash_movement_dialog.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/fake_printer.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

String som(int amount) => PosFormat.money(amount * 100, currency: "so'm");

late AppDatabase _db;
late FakeTransport printer;

Future<void> open(WidgetTester tester, {bool withPrinter = false}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  if (withPrinter) {
    await _db.writeSetting(
      PrinterSettings.settingKey,
      jsonEncode(
        const PrinterSettings(
          connection: PrinterConnection.network,
          address: '10.0.0.5',
        ).toJson(),
      ),
    );
  }
  printer = FakeTransport();
  await pumpPosApp(
    tester,
    db: _db,
    overrides: [
      printerTransportFactoryProvider.overrideWithValue(
        (s) => s.configured ? printer : null,
      ),
    ],
  );
}

Finder get dialog => find.byType(CashMovementDialog);

Finder inDialog(String text) =>
    find.descendant(of: dialog, matching: find.text(text));

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<List<CashMovement>> movements() => _db.select(_db.cashMovements).get();

void main() {
  testWidgets('F9: cash in with a reason; Enter saves', (tester) async {
    await open(tester);
    await press(tester, LogicalKeyboardKey.f9);
    expect(dialog, findsOneWidget);
    expect(inDialog('Kassada: ${som(0)}'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('cash-in')));
    await typeSlowly(tester, '50000');
    expect(inDialog(som(50000)), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('cash-reason-change')));
    await press(tester, LogicalKeyboardKey.enter);

    expect(dialog, findsNothing);
    expect(find.text('Kassaga ${som(50000)} kiritildi'), findsOneWidget);
    final saved = (await movements()).single;
    expect(
      (saved.type, saved.amountTiyin, saved.reason),
      (
        'in',
        5000000,
        'Mayda pul',
      ),
    );
    expect(saved.byUserId, testCashier.id);
  });

  testWidgets('cash out above the drawer and without a reason is refused', (
    tester,
  ) async {
    await open(tester);
    await press(tester, LogicalKeyboardKey.f9);
    // Standart — chiqarish.
    await typeSlowly(tester, '10000');
    await press(tester, LogicalKeyboardKey.enter);
    expect(inDialog('Sababni tanlang'), findsOneWidget);

    await tap(tester, find.byKey(const ValueKey('cash-reason-collection')));
    await press(tester, LogicalKeyboardKey.enter);
    expect(inDialog('Kassada faqat ${som(0)} bor'), findsOneWidget);
    expect(dialog, findsOneWidget);
    expect(await movements(), isEmpty);
  });

  testWidgets('shift page: in, out, list and X report update', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Smena'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bu smenada pul kiritilmagan va chiqarilmagan'),
      findsOneWidget,
    );

    await tap(tester, find.byKey(const ValueKey('shift-cash-in')));
    await typeSlowly(tester, '20000');
    await tap(tester, find.byKey(const ValueKey('cash-reason-change')));
    await tap(tester, find.byKey(const ValueKey('cash-confirm')));

    await tap(tester, find.byKey(const ValueKey('shift-cash-out')));
    await typeSlowly(tester, '5000');
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'Suv uchun',
    );
    await tap(tester, find.byKey(const ValueKey('cash-confirm')));

    expect(find.textContaining('Mayda pul'), findsOneWidget);
    expect(find.textContaining('Suv uchun'), findsOneWidget);
    expect(
      find.text(PosFormat.money(-500000, currency: "so'm")),
      findsOneWidget,
    );
    // X hisobot: kiritilgan 20 000, olingan 5 000, kassada 15 000.
    expect(find.text(som(15000)), findsOneWidget);
    expect(await movements(), hasLength(2));
  });

  testWidgets('X report receipt is printed from the shift page', (
    tester,
  ) async {
    await open(tester, withPrinter: true);
    await tester.tap(find.text('Smena'));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('shift-print')));
    expect(printer.jobs, hasLength(1));
    expect(
      containsBytes(
        printer.jobs.single,
        EscPos.encode('X hisobot', PrinterEncoding.cp866),
      ),
      isTrue,
    );
    expect(find.text('Printerga yuborildi'), findsOneWidget);
  });
}
