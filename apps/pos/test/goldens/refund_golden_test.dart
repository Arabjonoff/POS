import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/payment/checkout.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/pump_app.dart';
import '../helpers/sqlite.dart';
import 'golden_helpers.dart';

/// Ikki savdo (qat'iy vaqt): non + olma (chegirma bilan), cola.
Future<void> _seedSales(AppDatabase db) async {
  final shift = await db.select(db.shifts).getSingle();
  var minute = 0;
  final checkout = Checkout(
    SaleWriter(
      db,
      deviceNumber: 3,
      now: () => DateTime.utc(2026, 10, 15, 6, minute += 7),
    ),
  );
  const carts = [
    Cart(
      id: 'a',
      slot: 0,
      lines: [
        CartLine(
          id: 'l1',
          productId: 'p-non',
          name: 'Non issiq',
          unit: 'pcs',
          qtyMilli: 2000,
          priceTiyin: 400000,
          costTiyin: 300000,
        ),
        CartLine(
          id: 'l2',
          productId: 'p-olma',
          name: 'Olma qizil',
          unit: 'kg',
          weighted: true,
          qtyMilli: 1250,
          priceTiyin: 1500000,
          costTiyin: 1000000,
        ),
      ],
    ),
    Cart(
      id: 'b',
      slot: 0,
      lines: [
        CartLine(
          id: 'l3',
          productId: 'p-cola',
          name: 'Coca-Cola 1,5 L',
          unit: 'pcs',
          qtyMilli: 1000,
          priceTiyin: 1400000,
          costTiyin: 1100000,
        ),
      ],
    ),
  ];
  for (final cart in carts) {
    await checkout.complete(
      cart: cart,
      payment: PaymentDraft(totalTiyin: cart.totalTiyin),
      shiftId: shift.id,
      cashierId: 'cashier-1',
    );
  }
}

Future<void> _open(WidgetTester tester, Size size) async {
  final db = openTestDatabase();
  addTearDown(db.close);
  await seedCatalog(db);
  await pumpPosApp(
    tester,
    size: size,
    db: db,
    overrides: [
      connectionStatusProvider.overrideWithValue(ConnectionStatus.online),
      printerStatusProvider.overrideWithValue(PrinterStatus.unknown),
      pendingEventsProvider.overrideWith((ref) => Stream.value(0)),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 6, 30)),
    ],
  );
  await _seedSales(db);
  if (size.width < 600) {
    await tester.tap(find.byKey(const ValueKey('pos-refund')));
  } else {
    await tester.sendKeyEvent(LogicalKeyboardKey.f8);
  }
  await tester.pumpAndSettle();
}

void main() {
  goldenAcrossDevices('refund', 'find', _open);

  goldenAcrossDevices('refund', 'items', (tester, size) async {
    await _open(tester, size);
    await tester.tap(find.text('D3-000001'));
    await tester.pumpAndSettle();
    final more = find.byTooltip("Ko'paytirish").first;
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    final reason = find.byKey(const ValueKey('refund-reason-defective'));
    await tester.ensureVisible(reason);
    await tester.pumpAndSettle();
    await tester.tap(reason);
    await tester.pumpAndSettle();
  });
}
