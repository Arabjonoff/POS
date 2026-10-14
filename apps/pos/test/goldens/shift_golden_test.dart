import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/data/shifts/shift_service.dart';

import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

final DateTime _now = DateTime.utc(2026, 10, 14, 15, 15);

/// Ochiq smena: 100 000 boshlang'ich, uch savdo (naqd, karta, nasiya).
Future<AppDatabase> _shiftWithSales() async {
  final db = openTestDatabase();
  final shift = await ShiftService(db, now: () => _now).open(
    deviceId: testDevice.id,
    storeId: testDevice.storeId,
    cashierId: testCashier.id,
    openingCashTiyin: 10000000,
  );
  final writer = SaleWriter(
    db,
    deviceNumber: testDevice.number,
    now: () => _now,
  );
  for (final payment in const [
    SalePaymentInput.cash(amountTiyin: 4250000, receivedTiyin: 5000000),
    SalePaymentInput.card(amountTiyin: 1800000),
    SalePaymentInput.debt(amountTiyin: 600000),
  ]) {
    await writer.complete(
      CompletedSaleInput(
        shiftId: shift.id,
        cashierId: testCashier.id,
        customerId: payment.method == SalePaymentMethod.debt ? 'c1' : null,
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

Future<void> _pump(WidgetTester tester, Size size, AppDatabase db) async {
  await pumpPosApp(
    tester,
    size: size,
    db: db,
    withOpenShift: false,
    overrides: [
      connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
      printerStatusProvider.overrideWithValue(PrinterStatus.ready),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
}

Future<void> _type(WidgetTester tester, List<LogicalKeyboardKey> keys) async {
  for (final key in keys) {
    await tester.sendKeyEvent(key);
  }
  await tester.pumpAndSettle();
}

/// Smena: ochish kartasi, X hisobot, yopish (farq), Z hisobot.
void main() {
  goldenAcrossDevices('shift', 'open', (tester, size) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await _pump(tester, size, db);
    await _type(tester, const [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
    ]);
  });

  goldenAcrossDevices('shift', 'x_report', (tester, size) async {
    final db = await _shiftWithSales();
    addTearDown(db.close);
    await _pump(tester, size, db);
    await tester.tap(find.text('Smena'));
    await tester.pumpAndSettle();
  });

  goldenAcrossDevices('shift', 'close', (tester, size) async {
    final db = await _shiftWithSales();
    addTearDown(db.close);
    await _pump(tester, size, db);
    await tester.tap(find.text('Smena'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Smenani yopish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smenani yopish'));
    await tester.pumpAndSettle();
    await _type(tester, const [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
    ]);
  });

  goldenAcrossDevices('shift', 'z_report', (tester, size) async {
    final db = await _shiftWithSales();
    addTearDown(db.close);
    await _pump(tester, size, db);
    await tester.tap(find.text('Smena'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Smenani yopish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smenani yopish'));
    await tester.pumpAndSettle();
    await _type(tester, const [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.enter,
    ]);
  });
}
