import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/data/shifts/shift_service.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';

String som(int amount) => PosFormat.money(amount * 100, currency: "so'm");

const List<LogicalKeyboardKey> _digitKeys = [
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

/// Fizik klaviaturadan raqamlar (kassir yozishi).
Future<void> typeDigits(WidgetTester tester, String digits) async {
  for (final ch in digits.split('')) {
    await tester.sendKeyEvent(_digitKeys[int.parse(ch)]);
  }
  await tester.pump();
}

Future<Shift?> openShiftOf(AppDatabase db) =>
    ShiftService(db).currentShift(testDevice.id);

void main() {
  group('open shift', () {
    testWidgets('no sales until a shift is opened with starting cash', (
      tester,
    ) async {
      final (_, db) = await pumpPosApp(tester, withOpenShift: false);
      expect(find.text('Smenani oching'), findsOneWidget);
      expect(find.text('Smena yopiq'), findsOneWidget);
      expect(find.text('Tovarni skanerlang yoki qidiring'), findsNothing);

      await typeDigits(tester, '1500');
      await tester.tap(find.text('00'));
      await tester.pump();
      expect(find.text(som(150000)), findsOneWidget);

      await tester.tap(find.text('Smenani ochish'));
      await tester.pumpAndSettle();

      final shift = await openShiftOf(db);
      expect(shift, isNotNull);
      expect(shift!.openingCashTiyin, 150000 * 100);
      expect(shift.openedBy, testCashier.id);
      expect(find.text('Smenani oching'), findsNothing);
      expect(find.text('Tovarni skanerlang yoki qidiring'), findsOneWidget);
      expect(find.text('Smena ochiq'), findsOneWidget);
    });

    testWidgets('suggests the cash counted at the last close', (tester) async {
      final db = openTestDatabase();
      addTearDown(db.close);
      final service = ShiftService(db);
      final last = await service.open(
        deviceId: testDevice.id,
        storeId: testDevice.storeId,
        cashierId: testCashier.id,
        openingCashTiyin: 0,
      );
      await service.close(
        shiftId: last.id,
        closedBy: testCashier.id,
        countedCashTiyin: 50000 * 100,
      );

      await pumpPosApp(tester, db: db, withOpenShift: false);
      expect(find.text(som(50000)), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(find.text(som(5000)), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect((await openShiftOf(db))!.openingCashTiyin, 5000 * 100);
    });
  });

  group('close shift', () {
    Future<AppDatabase> withSales() async {
      final db = openTestDatabase();
      addTearDown(db.close);
      final shift = await ShiftService(db).open(
        deviceId: testDevice.id,
        storeId: testDevice.storeId,
        cashierId: testCashier.id,
        openingCashTiyin: 100000 * 100,
      );
      final writer = SaleWriter(db, deviceNumber: testDevice.number);
      for (final payment in const [
        SalePaymentInput.cash(amountTiyin: 3000000, receivedTiyin: 5000000),
        SalePaymentInput.card(amountTiyin: 2000000),
      ]) {
        await writer.complete(
          CompletedSaleInput(
            shiftId: shift.id,
            cashierId: testCashier.id,
            lines: [
              SaleLineInput(
                productId: 'p',
                name: 'Non',
                qtyMilli: 1000,
                priceTiyin: payment.amountTiyin,
                costTiyin: 0,
              ),
            ],
            payments: [payment],
          ),
        );
      }
      return db;
    }

    testWidgets('X report matches sales; counted cash shows the shortage', (
      tester,
    ) async {
      final db = await withSales();
      await pumpPosApp(tester, db: db, withOpenShift: false);

      await tester.tap(find.text('Smena'));
      await tester.pumpAndSettle();
      expect(find.text('X hisobot'), findsOneWidget);
      expect(find.text('Savdolar · 2 ta chek'), findsOneWidget);
      expect(find.text(som(50000)), findsOneWidget);
      expect(find.text(som(30000)), findsOneWidget);
      expect(find.text(som(20000)), findsOneWidget);
      expect(find.text(som(100000)), findsOneWidget);
      // Kutilgan naqd: 100 000 + 30 000.
      expect(find.text(som(130000)), findsOneWidget);

      await tester.tap(find.text('Smenani yopish'));
      await tester.pumpAndSettle();
      expect(find.text('Kassadagi pulni sanang'), findsOneWidget);

      await typeDigits(tester, '125000');
      expect(find.text('Kam'), findsOneWidget);
      expect(find.text(som(-5000)), findsOneWidget);

      await tester.tap(find.text('Yopish'));
      await tester.pumpAndSettle();

      expect(find.text('Smena yopildi'), findsWidgets);
      expect(find.text('Z hisobot'), findsOneWidget);
      expect(find.text('Sanalgan naqd'), findsOneWidget);
      expect(find.text(som(125000)), findsOneWidget);
      expect(find.text('Kam'), findsOneWidget);
      expect(find.text('Smena yopiq'), findsOneWidget);

      final closed = await db.select(db.shifts).getSingle();
      expect(closed.closedAt, isNotNull);
      expect(closed.closedBy, testCashier.id);
      expect(closed.countedCashTiyin, 125000 * 100);

      await tester.tap(find.text('Kassaga qaytish'));
      await tester.pumpAndSettle();
      expect(find.text('Smenani oching'), findsOneWidget);
      // Taklif — hozir sanalgan summa.
      expect(find.text(som(125000)), findsOneWidget);
    });

    testWidgets('cancel keeps the shift open', (tester) async {
      final db = await withSales();
      await pumpPosApp(tester, db: db, withOpenShift: false);
      await tester.tap(find.text('Smena'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smenani yopish'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Kassadagi pulni sanang'), findsNothing);
      expect(find.text('X hisobot'), findsOneWidget);
      expect(await openShiftOf(db), isNotNull);
    });
  });
}
