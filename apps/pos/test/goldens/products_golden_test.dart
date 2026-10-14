import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

/// Katalog + qoldiqlar: sut kam qolgan, cola manfiy, tannarxlar.
Future<AppDatabase> _seed() async {
  final db = openTestDatabase();
  await seedCatalog(db);
  for (final (id, cost, stock) in const [
    ('p-non', 300000, 24000),
    ('p-patir', 600000, 8000),
    ('p-tuxum', 110000, 120000),
    ('p-sut', 950000, 3000),
    ('p-kartoshka', 450000, 52500),
    ('p-piyoz', 300000, 18250),
    ('p-olma', 1100000, 9750),
    ('p-cola', 1100000, -2000),
    ('p-choy', 1800000, 14000),
    ('p-shakar', 1100000, 40000),
    ('p-nonvoy', 650000, 6000),
  ]) {
    await (db.update(db.products)..where((p) => p.id.equals(id))).write(
      ProductsCompanion(
        costPriceTiyin: Value(cost),
        minStockMilli: Value(id == 'p-sut' ? 5000 : 0),
      ),
    );
    await db
        .into(db.productStock)
        .insert(
          ProductStockCompanion.insert(
            productId: id,
            storeId: 'store-1',
            qtyMilli: stock,
            updatedAt: DateTime.utc(2026, 10, 15),
          ),
        );
  }
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
  await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  // Telefonda pastki menyu: "Tovarlar".
  final nav = find.text('Tovarlar');
  if (size.width < 600 && nav.evaluate().isNotEmpty) {
    await tester.tap(nav.last);
    await tester.pumpAndSettle();
  }
}

void main() {
  goldenAcrossDevices('products', 'list', _open);

  goldenAcrossDevices('products', 'card', (tester, size) async {
    await _open(tester, size);
    await tester.tap(find.text('Olma qizil'));
    await tester.pumpAndSettle();
  });
}
