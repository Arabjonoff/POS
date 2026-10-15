import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/refunds/refund_dialog.dart';
import 'package:pos_app/features/sales/sales_screen.dart';
import 'package:pos_app/features/settings/settings_screen.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/fake_printer.dart';
import '../helpers/keyboard.dart';
import '../helpers/pump_app.dart';
import '../helpers/sale_history_seed.dart';
import '../helpers/sqlite.dart';

late AppDatabase _db;
late FakeTransport printer;

Finder sale(String number) => find.byKey(ValueKey('sale-$number'));

Future<void> open(
  WidgetTester tester, {
  bool withPrinter = true,
  Size size = const Size(1440, 900),
}) async {
  _db = openTestDatabase();
  addTearDown(_db.close);
  await seedCatalog(_db);
  await seedSaleHistory(_db);
  if (withPrinter) {
    await _db.writeSetting(
      PrinterSettings.settingKey,
      jsonEncode(
        const PrinterSettings(
          connection: PrinterConnection.network,
          address: '192.168.1.50',
        ).toJson(),
      ),
    );
  }
  printer = FakeTransport();
  await pumpPosApp(
    tester,
    db: _db,
    size: size,
    overrides: [
      clockProvider.overrideWithValue(() => historyNow),
      printerTransportFactoryProvider.overrideWithValue(
        (s) => s.configured ? printer : null,
      ),
    ],
  );
  await tapNav(tester, 'Cheklar');
}

void main() {
  testWidgets('today: newest first, totals, refund badges', (tester) async {
    await open(tester);
    expect(find.byType(SalesScreen), findsOneWidget);
    expect(sale('D3-000002'), findsOneWidget);
    expect(sale('D3-000001'), findsOneWidget);
    expect(sale('D3-000003'), findsNothing);
    expect(
      tester.getTopLeft(sale('D3-000002')).dy,
      lessThan(tester.getTopLeft(sale('D3-000001')).dy),
    );
    expect(
      find.text("2 ta chek · ${PosFormat.money(7300000, currency: "so'm")}"),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sale('D3-000002'),
        matching: find.text('Qisman qaytarilgan'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sale('D3-000002'),
        matching: find.text('11:30 · Aziza · Karimova Dilnoza'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sale('D3-000002'),
        matching: find.text('1 pozitsiya · Karta · Nasiya'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Faqat shu kassada sotilgan cheklar ko\'rinadi'),
      findsOneWidget,
    );
  });

  testWidgets('yesterday and payment filters', (tester) async {
    await open(tester);
    await tester.tap(find.text('Kecha'));
    await tester.pumpAndSettle();
    expect(sale('D3-000003'), findsOneWidget);
    expect(sale('D3-000001'), findsNothing);
    expect(
      find.descendant(
        of: sale('D3-000003'),
        matching: find.text('Qaytarilgan'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Bugun'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('sales-filter-SalePaymentFilter.debt')),
    );
    await tester.pumpAndSettle();
    expect(sale('D3-000002'), findsOneWidget);
    expect(sale('D3-000001'), findsNothing);
  });

  testWidgets('search by product finds an older receipt', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('sales-search')), 'olma');
    await tester.pumpAndSettle();
    expect(sale('D3-000003'), findsOneWidget);
    expect(sale('D3-000001'), findsNothing);
    // Qidiruvda sana ham ko'rinadi.
    expect(find.textContaining('14.10.2026 18:00'), findsOneWidget);
  });

  testWidgets('scanning the receipt barcode opens that receipt', (
    tester,
  ) async {
    await open(tester);
    await scanCode(tester, 'd3-000003');
    expect(find.byKey(const ValueKey('sale-detail')), findsOneWidget);
    expect(find.byKey(const ValueKey('sale-receipt-preview')), findsOneWidget);
    // Qaytarishlar ro'yxati: summa va sabab.
    expect(find.text('Qaytarishlar'), findsOneWidget);
    expect(find.textContaining('Yaroqsiz'), findsOneWidget);
    // To'liq qaytarilgan chekni qayta qaytarib bo'lmaydi.
    final refund = tester.widget<PosButton>(
      find.byKey(const ValueKey('sale-refund')),
    );
    expect(refund.onPressed, isNull);

    await scanCode(tester, 'd3-999999');
    expect(find.text('Chek topilmadi: D3-999999'), findsOneWidget);
  });

  testWidgets('reprint sends a COPY of the chosen receipt', (tester) async {
    await open(tester);
    await tester.tap(sale('D3-000001'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sale-reprint')));
    await tester.pumpAndSettle();
    final job = printer.jobs.single;
    expect(
      containsBytes(job, EscPos.encode('D3-000001', PrinterEncoding.cp866)),
      isTrue,
    );
    expect(
      containsBytes(job, EscPos.encode('NUSXA', PrinterEncoding.cp866)),
      isTrue,
    );
    expect(find.text('Printerga yuborildi'), findsOneWidget);

    // Ctrl+P — o'sha chek yana.
    await pressCtrl(tester, LogicalKeyboardKey.keyP);
    expect(printer.jobs, hasLength(2));
  });

  testWidgets('printer off: clear message and retry', (tester) async {
    await open(tester);
    printer.fail = true;
    await tester.tap(sale('D3-000001'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sale-reprint')));
    await tester.pumpAndSettle();
    expect(find.text('Chek chiqmadi'), findsOneWidget);
    printer.fail = false;
    await tester.tap(find.text('Qayta chop etish').last);
    await tester.pumpAndSettle();
    expect(printer.jobs, hasLength(1));
  });

  testWidgets('no printer: "set up" opens the settings', (tester) async {
    await open(tester, withPrinter: false);
    await tester.tap(sale('D3-000001'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sale-reprint')));
    await tester.pumpAndSettle();
    expect(find.text('Avval printerni sozlang'), findsOneWidget);
    await tester.tap(find.text('Sozlash'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('refund opens with this receipt already chosen', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(sale('D3-000001'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sale-refund')));
    await tester.pumpAndSettle();
    expect(find.byType(RefundDialog), findsOneWidget);
    expect(find.text('Qaytarish · D3-000001'), findsOneWidget);
  });

  testWidgets('phone: list, then detail with back (Esc)', (tester) async {
    await open(tester, size: const Size(390, 844));
    await tester.tap(sale('D3-000001'));
    await tester.pumpAndSettle();
    expect(sale('D3-000002'), findsNothing);
    expect(find.byKey(const ValueKey('sale-detail-back')), findsOneWidget);
    await press(tester, LogicalKeyboardKey.escape);
    expect(sale('D3-000002'), findsOneWidget);
  });

  testWidgets('Ctrl+7 and F7 on the kassa open the receipts', (tester) async {
    await open(tester);
    await pressCtrl(tester, LogicalKeyboardKey.digit1);
    expect(find.byType(SalesScreen), findsNothing);
    await press(tester, LogicalKeyboardKey.f7);
    expect(find.byType(SalesScreen), findsOneWidget);
    await pressCtrl(tester, LogicalKeyboardKey.digit1);
    await pressCtrl(tester, LogicalKeyboardKey.digit7);
    expect(find.byType(SalesScreen), findsOneWidget);
  });
}
