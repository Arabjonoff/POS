import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/payment/checkout.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';
import 'package:pos_app/features/printing/receipt_loader.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = openTestDatabase();
    await seedCatalog(db);
    await db
        .into(db.stores)
        .insert(
          StoresCompanion.insert(
            id: 'store-1',
            name: 'Baraka market',
            address: const Value('Chilonzor 7'),
            receiptFooter: const Value('Rahmat!'),
          ),
        );
    await db
        .into(db.staffUsers)
        .insert(
          StaffUsersCompanion.insert(
            id: 'cashier-1',
            fullName: 'Aziza',
            role: 'cashier',
          ),
        );
    await db
        .into(db.customers)
        .insert(
          CustomersCompanion.insert(
            id: 'c1',
            fullName: 'Karimova',
            balanceTiyin: const Value(1000000),
          ),
        );
    await db
        .into(db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: 'shift-1',
            storeId: 'store-1',
            deviceId: 'device-1',
            openedBy: 'cashier-1',
            openedAt: DateTime.utc(2026, 10, 15, 8),
            openingCashTiyin: 0,
          ),
        );
  });
  tearDown(() => db.close());

  test('a recorded sale becomes receipt data', () async {
    const cart = Cart(
      id: 'cart',
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
    );
    // 8 000 + 18 750 = 26 750: karta 6 750, nasiya 10 000, naqd 10 000 (20 000 berildi).
    final payment = PaymentDraft(
      totalTiyin: cart.totalTiyin,
      mode: PayMode.mixed,
      customerId: 'c1',
    ).copyWith(cardTiyin: 675000, debtTiyin: 1000000, receivedTiyin: 2000000);
    final done =
        await Checkout(
          SaleWriter(db, deviceNumber: 3),
          storeId: 'store-1',
        ).complete(
          cart: cart,
          payment: payment,
          shiftId: 'shift-1',
          cashierId: 'cashier-1',
        );

    final data = (await ReceiptLoader(db).load(done.sale.id))!;
    expect(data.storeName, 'Baraka market');
    expect(data.storeAddress, 'Chilonzor 7');
    expect(data.footer, 'Rahmat!');
    expect(data.number, done.sale.number);
    expect(data.cashierName, 'Aziza');
    expect(
      [for (final l in data.lines) (l.name, l.qtyMilli, l.unit, l.totalTiyin)],
      [
        ('Non issiq', 2000, UnitCode.pcs, 800000),
        ('Olma qizil', 1250, UnitCode.kg, 1875000),
      ],
    );
    expect(data.totalTiyin, 2675000);
    expect([for (final p in data.payments) p.method], ['cash', 'card', 'debt']);
    expect(data.payments.first.receivedTiyin, 2000000);
    expect(data.changeTiyin, 1000000);
    expect(data.customerName, 'Karimova');
    // Avvalgi 10 000 (serverdan) emas: lokal daftarda faqat shu savdo.
    expect(data.customerDebtTiyin, 1000000);
  });

  test('unknown sale → null', () async {
    expect(await ReceiptLoader(db).load('nope'), isNull);
  });
}
