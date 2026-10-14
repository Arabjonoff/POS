import 'package:flutter/material.dart' show ValueKey;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/inventory/count_store.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

/// "Sut" bo'yicha qoralama: sut kam, tuxum ortiqcha.
Future<(AppDatabase, String)> _seed() async {
  final db = openTestDatabase();
  await seedCatalog(db);
  for (final (id, qty) in const [('p-sut', 5000), ('p-tuxum', 30000)]) {
    await db
        .into(db.productStock)
        .insert(
          ProductStockCompanion.insert(
            productId: id,
            storeId: 'store-1',
            qtyMilli: qty,
            updatedAt: DateTime.utc(2026, 10, 15),
          ),
        );
  }
  final store = CountStore(db, now: () => DateTime.utc(2026, 10, 15, 13));
  final id = await store.create(categoryId: 'c-milk');
  await store.addCounted(id, 'p-sut', qtyMilli: 3000);
  await store.addCounted(id, 'p-tuxum', qtyMilli: 32000);
  return (db, id);
}

void main() {
  goldenAcrossDevices('inventory', 'editor', (tester, size) async {
    final (db, id) = await _seed();
    addTearDown(db.close);
    await pumpPosApp(
      tester,
      size: size,
      db: db,
      overrides: [
        connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
        printerStatusProvider.overrideWithValue(PrinterStatus.ready),
        pendingEventsProvider.overrideWith((ref) => Stream.value(0)),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 14)),
      ],
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    final nav = find.text('Tovarlar');
    if (size.width < 600 && nav.evaluate().isNotEmpty) {
      await tester.tap(nav.last);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('products-inventory')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('count-$id')));
    await tester.pumpAndSettle();
  });
}
