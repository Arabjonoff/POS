import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show TextField, ValueKey;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

Future<AppDatabase> _seed() async {
  final db = openTestDatabase();
  final at = DateTime.utc(2026, 10, 12, 6);
  await db.batch((b) {
    b
      ..insertAll(db.customers, [
        CustomersCompanion.insert(
          id: 'c1',
          fullName: 'Karimova Dilnoza',
          phone: const Value('+998 90 123 45 67'),
          debtLimitTiyin: const Value(50000000),
        ),
        CustomersCompanion.insert(
          id: 'c2',
          fullName: 'Olim aka',
          phone: const Value('+998 93 555 11 22'),
        ),
        CustomersCompanion.insert(id: 'c3', fullName: 'Aziz Rahimov'),
        CustomersCompanion.insert(id: 'c4', fullName: 'Zarina opa'),
        // T-103: boshlang'ich avans — do'kon mijozga qarzdor.
        CustomersCompanion.insert(id: 'c5', fullName: 'Avansli mijoz'),
      ])
      ..insert(
        db.staffUsers,
        StaffUsersCompanion.insert(
          id: 'cashier-1',
          fullName: 'Aziza',
          role: 'cashier',
        ),
      )
      ..insertAll(db.debtEntries, [
        DebtEntriesCompanion.insert(
          id: 'o5',
          customerId: 'c5',
          amountTiyin: -5000000,
          type: 'opening',
          at: DateTime.utc(2026, 10, 1, 7),
        ),
        DebtEntriesCompanion.insert(
          id: 'd1',
          customerId: 'c1',
          amountTiyin: 23500000,
          type: 'sale',
          byUserId: const Value('cashier-1'),
          at: at,
        ),
        DebtEntriesCompanion.insert(
          id: 'd2',
          customerId: 'c1',
          amountTiyin: 12000000,
          type: 'sale',
          byUserId: const Value('cashier-1'),
          at: at.add(const Duration(days: 1)),
        ),
        DebtEntriesCompanion.insert(
          id: 'd3',
          customerId: 'c1',
          amountTiyin: -10000000,
          type: 'payment',
          method: const Value('cash'),
          byUserId: const Value('cashier-1'),
          at: at.add(const Duration(days: 2)),
        ),
        DebtEntriesCompanion.insert(
          id: 'd4',
          customerId: 'c2',
          amountTiyin: 4500000,
          type: 'sale',
          at: at,
        ),
      ]);
  });
  return db;
}

Future<void> _open(WidgetTester tester, Size size) async {
  final db = await _seed();
  addTearDown(db.close);
  await pumpPosApp(
    tester,
    size: size,
    db: db,
    overrides: [
      connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
      printerStatusProvider.overrideWithValue(PrinterStatus.ready),
      pendingEventsProvider.overrideWith((ref) => Stream.value(0)),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 10)),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  final nav = find.byTooltip('Mijozlar');
  if (size.width < 600 && nav.evaluate().isNotEmpty) {
    await tester.tap(nav.last);
    await tester.pumpAndSettle();
  }
}

void main() {
  goldenAcrossDevices('customers', 'list', _open);

  goldenAcrossDevices('customers', 'card', (tester, size) async {
    await _open(tester, size);
    await tester.tap(find.byKey(const ValueKey('customer-c1')));
    await tester.pumpAndSettle();
  });

  // T-103: avansli mijoz kartasi — "Mijoz haqi (avans)", to'lov tugmasi yo'q.
  goldenAcrossDevices('customers', 'card_credit', (tester, size) async {
    await _open(tester, size);
    await tester.ensureVisible(find.byKey(const ValueKey('customer-c5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('customer-c5')));
    await tester.pumpAndSettle();
  });

  // T-103: yangi mijoz — boshlang'ich qarz bilan.
  goldenAcrossDevices('customers', 'new_opening', (tester, size) async {
    await _open(tester, size);
    await tester.tap(find.byKey(const ValueKey('customers-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-customer-name')),
      'Eski qarzdor',
    );
    await tester.tap(find.byKey(const ValueKey('opening-debt')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('new-customer-opening-amount')),
        matching: find.byType(TextField),
      ),
      '1500000',
    );
    await tester.pumpAndSettle();
  });
}
