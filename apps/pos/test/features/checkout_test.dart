import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/payment/checkout.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';

import '../helpers/sqlite.dart';

const Cart cart = Cart(
  id: 'cart',
  slot: 0,
  customerId: 'c1',
  discount: Discount.amount(50000, approvedBy: 'manager-1'),
  lines: [
    CartLine(
      id: 'l1',
      productId: 'p-non',
      name: 'Non',
      unit: 'pcs',
      barcode: '4780000000014',
      qtyMilli: 2000,
      priceTiyin: 400000,
      costTiyin: 300000,
    ),
    CartLine(
      id: 'l2',
      productId: 'p-olma',
      name: 'Olma',
      unit: 'kg',
      weighted: true,
      qtyMilli: 1250,
      priceTiyin: 1500000,
      costTiyin: 1000000,
      discount: Discount.percent(1000),
    ),
  ],
);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = openTestDatabase();
    await db
        .into(db.customers)
        .insert(CustomersCompanion.insert(id: 'c1', fullName: 'Karimova'));
    await db
        .into(db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: 'shift-1',
            storeId: 'store-1',
            deviceId: 'device-1',
            openedBy: 'cashier-1',
            openedAt: DateTime.utc(2026, 10, 14, 8),
            openingCashTiyin: 0,
          ),
        );
  });
  tearDown(() => db.close());

  Checkout checkout({IdGenerator? ids}) =>
      Checkout(SaleWriter(db, deviceNumber: 3, newId: ids), storeId: 'store-1');

  Future<int> count(TableInfo<Table, Object?> table) async =>
      (await db.select(table).get()).length;

  test('cart + mixed payment → one sale with all parts', () async {
    // 8 000 + (18 750 − 1 875) − 500 = 24 375 so'm.
    expect(cart.totalTiyin, 2437500);
    final payment = const PaymentDraft(
      totalTiyin: 2437500,
      mode: PayMode.mixed,
      customerId: 'c1',
    ).copyWith(cardTiyin: 1000000, debtTiyin: 437500, receivedTiyin: 1500000);

    final result = await checkout().complete(
      cart: cart,
      payment: payment,
      shiftId: 'shift-1',
      cashierId: 'cashier-1',
    );
    expect(result.sale.number, 'D3-000001');
    expect(result.changeTiyin, 500000);

    final sale = await db.select(db.sales).getSingle();
    expect(sale.subtotalTiyin, 2487500);
    expect(sale.discountTiyin, 50000);
    expect(sale.totalTiyin, 2437500);
    expect(sale.customerId, 'c1');
    expect(sale.approvedBy, 'manager-1');
    final items = await (db.select(
      db.saleItems,
    )..orderBy([(i) => OrderingTerm.asc(i.position)])).get();
    expect(
      [for (final i in items) (i.qtyMilli, i.discountTiyin, i.totalTiyin)],
      [
        (2000, 0, 800000),
        (1250, 187500, 1687500),
      ],
    );
    final payments = await db.select(db.salePayments).get();
    expect(
      {for (final p in payments) p.method: (p.amountTiyin, p.changeTiyin)},
      {
        'cash': (1000000, 500000),
        'card': (1000000, 0),
        'debt': (437500, 0),
      },
    );
    expect(await count(db.stockMovements), 2);
    expect(await count(db.outboxEvents), 1);
    final balance = (await CustomerDirectory(db).byId('c1'))!.balanceTiyin;
    expect(balance, 437500);
  });

  test('limit approver wins over the discount approver', () async {
    await checkout().complete(
      cart: cart,
      payment: const PaymentDraft(
        totalTiyin: 2437500,
        mode: PayMode.debt,
        customerId: 'c1',
      ),
      shiftId: 'shift-1',
      cashierId: 'cashier-1',
      debtApprovedBy: 'owner-1',
    );
    expect((await db.select(db.sales).getSingle()).approvedBy, 'owner-1');
  });

  test('a failure in the middle writes nothing (atomic)', () async {
    var n = 0;
    String failing() {
      // Savdo, hodisa va birinchi qator yozilgach — xato.
      if (++n > 4) throw StateError('disk full');
      return 'id-$n';
    }

    await expectLater(
      checkout(ids: failing).complete(
        cart: cart,
        payment: const PaymentDraft(
          totalTiyin: 2437500,
          mode: PayMode.debt,
          customerId: 'c1',
        ),
        shiftId: 'shift-1',
        cashierId: 'cashier-1',
      ),
      throwsStateError,
    );
    for (final table in <TableInfo<Table, Object?>>[
      db.sales,
      db.saleItems,
      db.salePayments,
      db.stockMovements,
      db.debtEntries,
      db.outboxEvents,
      db.docCounters,
    ]) {
      expect(await count(table), 0, reason: table.actualTableName);
    }
    // Keyingi urinishda chek raqami yo'qolmaydi.
    final ok = await checkout().complete(
      cart: cart,
      payment: const PaymentDraft(totalTiyin: 2437500),
      shiftId: 'shift-1',
      cashierId: 'cashier-1',
    );
    expect(ok.sale.number, 'D3-000001');
  });

  test('payment that does not match the cart is refused', () async {
    expect(
      () => checkout().complete(
        cart: cart,
        payment: const PaymentDraft(totalTiyin: 100),
        shiftId: 'shift-1',
        cashierId: 'cashier-1',
      ),
      throwsA(isA<InvalidSaleException>()),
    );
    expect(await count(db.sales), 0);
  });
}
