import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show ValueKey;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/pump_app.dart';
import '../helpers/report_vectors.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

const StaffUser _owner = StaffUser(
  id: 'owner-1',
  fullName: 'Dilshod',
  role: 'owner',
  isActive: true,
);

Future<AppDatabase> _seed() async {
  final db = await seedReportVectors(openTestDatabase());
  final at = DateTime.utc(2026, 10, 10, 6);
  final [non, olma, sut] = [
    for (final p in rows(vectors['products'])) p['id'] as String,
  ];
  await db.batch((b) {
    b
      ..insertAll(db.customers, [
        CustomersCompanion.insert(
          id: 'c1',
          fullName: 'Karimova Dilnoza',
          phone: const Value('+998 90 123 45 67'),
        ),
        CustomersCompanion.insert(id: 'c2', fullName: 'Olim aka'),
      ])
      ..insertAll(db.debtEntries, [
        DebtEntriesCompanion.insert(
          id: 'd1',
          customerId: 'c1',
          amountTiyin: 25500000,
          type: 'sale',
          at: at,
        ),
        DebtEntriesCompanion.insert(
          id: 'd2',
          customerId: 'c2',
          amountTiyin: 4500000,
          type: 'sale',
          at: at,
        ),
      ])
      ..insertAll(db.productStock, [
        for (final (id, qty) in [(non, 4000), (olma, -500), (sut, 2000)])
          ProductStockCompanion.insert(
            productId: id,
            storeId: 'store-1',
            qtyMilli: qty,
            updatedAt: at,
          ),
      ])
      ..update(
        db.products,
        const ProductsCompanion(minStockMilli: Value(10000)),
        where: (p) => p.id.equals(sut),
      );
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
    session: const Session(
      stage: SessionStage.unlocked,
      device: testDevice,
      user: _owner,
    ),
    overrides: [
      connectionStatusProvider.overrideWithValue(ConnectionStatus.offline),
      printerStatusProvider.overrideWithValue(PrinterStatus.ready),
      pendingEventsProvider.overrideWith((ref) => Stream.value(3)),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 10)),
    ],
  );
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  final nav = find.text('Hisobotlar');
  if (size.width < 600 && nav.evaluate().length == 1) {
    await tester.tap(nav);
    await tester.pumpAndSettle();
  }
}

void main() {
  goldenAcrossDevices('reports', 'today', _open);

  goldenAcrossDevices('reports', 'week', (tester, size) async {
    await _open(tester, size);
    await tester.tap(find.byKey(const ValueKey('reports-period-last7Days')));
    await tester.pumpAndSettle();
  });
}
