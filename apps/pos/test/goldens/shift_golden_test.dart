import 'package:flutter/material.dart' show Scrollable, ValueKey;
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

/// Ochiq smena: 100 000 boshlang'ich, uch savdo (naqd, karta, nasiya),
/// kassa puli: +20 000 mayda pul, −60 000 inkassatsiya.
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
  final shifts = ShiftService(db, now: () => _now);
  await shifts.moveCash(
    shiftId: shift.id,
    type: CashMovementType.cashIn,
    amountTiyin: 2000000,
    by: testCashier.id,
    reason: 'Mayda pul',
  );
  await shifts.moveCash(
    shiftId: shift.id,
    type: CashMovementType.cashOut,
    amountTiyin: 6000000,
    by: testCashier.id,
    reason: 'Inkassatsiya',
  );
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
    await tester.tap(_shiftButton());
    await tester.pumpAndSettle();
  });

  /// Smena sahifasi pastida: kassa puli harakatlari ro'yxati.
  goldenAcrossDevices('shift', 'cash_list', (tester, size) async {
    final db = await _shiftWithSales();
    addTearDown(db.close);
    await _pump(tester, size, db);
    await tester.tap(_shiftButton());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('shift-cash-out')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Inkassatsiya'));
    await tester.pumpAndSettle();
  });

  /// F9: kassadan pul chiqarish — summa va sabab tanlangan.
  goldenAcrossDevices('shift', 'cash_out', (tester, size) async {
    final db = await _shiftWithSales();
    addTearDown(db.close);
    await _pump(tester, size, db);
    if (size.width < 600) {
      await tester.tap(_shiftButton());
      await tester.pumpAndSettle();
      final out = find.byKey(const ValueKey('shift-cash-out'));
      await tester.ensureVisible(out);
      await tester.pumpAndSettle();
      await tester.tap(out);
    } else {
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
    }
    await tester.pumpAndSettle();
    await _type(tester, const [
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit0,
    ]);
    final reason = find.byKey(const ValueKey('cash-reason-expense'));
    await tester.ensureVisible(reason);
    await tester.pumpAndSettle();
    await tester.tap(reason);
    await tester.pumpAndSettle();
  });

  goldenAcrossDevices('shift', 'close', (tester, size) async {
    final db = await _shiftWithSales();
    addTearDown(db.close);
    await _pump(tester, size, db);
    await tester.tap(_shiftButton());
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
    await tester.tap(_shiftButton());
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

/// Smena tugmasi: desktopda yozuvli, telefonda ikon (tooltip).
Finder _shiftButton() {
  final text = find.text('Smena');
  return text.evaluate().isNotEmpty ? text : find.byTooltip('Smena');
}
