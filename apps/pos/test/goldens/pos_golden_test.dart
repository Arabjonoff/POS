import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show ValueKey;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/catalog/product_catalog.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/cart/cart_controller.dart';
import 'package:pos_ui/pos_ui.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

Future<(ProviderContainer, AppDatabase)> _open(
  WidgetTester tester,
  Size size,
) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  await seedCatalog(db);
  final result = await pumpPosApp(
    tester,
    size: size,
    db: db,
    overrides: [
      connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
      printerStatusProvider.overrideWithValue(PrinterStatus.ready),
      pendingEventsProvider.overrideWith((ref) => Stream.value(0)),
      clockProvider.overrideWithValue(
        () => DateTime.utc(2026, 10, 14, 15, 15),
      ),
    ],
  );
  return result;
}

/// Savat: 4 qator (vaznli, chegirmali), chek chegirmasi, ikkinchi chek.
Future<void> _fillCart(WidgetTester tester, ProviderContainer c) async {
  final catalog = await c.read(productCatalogProvider.future);
  final cart = c.read(cartControllerProvider.notifier)
    ..add(catalog.byId('p-non')!)
    ..add(catalog.byId('p-non')!)
    ..add(catalog.byId('p-olma')!, qtyMilli: 1250)
    ..add(catalog.byId('p-sut')!)
    ..add(catalog.byId('p-choy')!);
  final state = c.read(cartControllerProvider).requireValue;
  cart
    ..setLineDiscount(state.cart.lines[1].id, const Discount.percent(1000))
    ..setCartDiscount(const Discount.amount(50000))
    ..newCart()
    ..add(catalog.byId('p-cola')!)
    ..switchTo(0)
    ..select(state.cart.lines[2].id);
  await tester.pumpAndSettle();
}

void main() {
  goldenAcrossDevices('pos', 'cart', (tester, size) async {
    final (c, _) = await _open(tester, size);
    await _fillCart(tester, c);
  });

  goldenAcrossDevices('pos', 'search', (tester, size) async {
    final (c, _) = await _open(tester, size);
    await _fillCart(tester, c);
    for (final key in [
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyN,
    ]) {
      await tester.sendKeyEvent(key);
    }
    // Inson yozuvi skaner buferidan ~70 ms keyin qidiruvga tushadi.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  });

  goldenAcrossDevices('pos', 'empty', (tester, size) async {
    await _open(tester, size);
  });

  /// To'lov oynasi: naqd, 100 000 berildi — katta yashil qaytim.
  goldenAcrossDevices('pos', 'pay_cash', (tester, size) async {
    final (c, _) = await _open(tester, size);
    await _fillCart(tester, c);
    await tester.sendKeyEvent(LogicalKeyboardKey.f12);
    await tester.pumpAndSettle();
    await tester.tap(find.text(PosFormat.moneyAmount(10000000)));
    await tester.pumpAndSettle();
  });

  /// Nasiya: mijoz tanlangan, limitdan oshadi — ogohlantirish.
  goldenAcrossDevices('pos', 'pay_debt', (tester, size) async {
    final (c, db) = await _open(tester, size);
    await db
        .into(db.customers)
        .insert(
          CustomersCompanion.insert(
            id: 'c1',
            fullName: 'Karimova Dilnoza',
            phone: const Value('+998 90 123 45 67'),
            debtLimitTiyin: const Value(5000000),
            balanceTiyin: const Value(3500000),
          ),
        );
    await _fillCart(tester, c);
    c.read(cartControllerProvider.notifier).setCustomer('c1');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f12);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-mode-debt')));
    await tester.pumpAndSettle();
  });
}
