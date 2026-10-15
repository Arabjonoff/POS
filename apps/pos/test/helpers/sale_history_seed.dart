import 'package:drift/drift.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Cheklar tarixi uchun "hozir": 15.10.2026 15:00 Toshkent.
final DateTime historyNow = DateTime.utc(2026, 10, 15, 10);

/// Uchta chek (`receipt-history.md` testlari):
/// - D3-000001 — bugun 10:05, naqd, Non ×2 + Sut, 25 000 so'm;
/// - D3-000002 — bugun 11:30, karta + nasiya, Karimova Dilnoza, Choy,
///   48 000 so'm, qisman qaytarilgan (5 000);
/// - D3-000003 — kecha 18:00, naqd, Olma, 12 000 so'm, to'liq qaytarilgan.
Future<void> seedSaleHistory(AppDatabase db) async {
  await db
      .into(db.staffUsers)
      .insert(
        StaffUsersCompanion.insert(
          id: 'cashier-1',
          fullName: 'Aziza',
          role: 'cashier',
        ),
        mode: InsertMode.insertOrIgnore,
      );
  await db
      .into(db.shifts)
      .insert(
        ShiftsCompanion.insert(
          id: 'shift-test',
          storeId: 'store-1',
          deviceId: 'device-1',
          openedBy: 'cashier-1',
          openedAt: DateTime.utc(2026, 10, 14, 3),
          openingCashTiyin: 0,
        ),
        mode: InsertMode.insertOrIgnore,
      );
  await db
      .into(db.customers)
      .insert(
        CustomersCompanion.insert(id: 'c1', fullName: 'Karimova Dilnoza'),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> sale(
    String id,
    String number,
    DateTime at,
    List<(String, String, int, int)> items,
    List<(String, int)> payments, {
    String? customerId,
    String status = 'completed',
  }) async {
    final total = items.fold(0, (s, i) => s + i.$4);
    await db
        .into(db.sales)
        .insert(
          SalesCompanion.insert(
            id: id,
            shiftId: 'shift-test',
            cashierId: 'cashier-1',
            customerId: Value(customerId),
            number: number,
            subtotalTiyin: total,
            discountTiyin: 0,
            totalTiyin: total,
            status: Value(status),
            soldAt: at,
          ),
        );
    for (final (i, (productId, name, qty, sum)) in items.indexed) {
      await db
          .into(db.saleItems)
          .insert(
            SaleItemsCompanion.insert(
              id: '$id-i$i',
              saleId: id,
              position: i,
              productId: productId,
              nameSnapshot: name,
              qtyMilli: qty,
              priceTiyin: sum * 1000 ~/ qty,
              costTiyin: 0,
              discountTiyin: 0,
              totalTiyin: sum,
            ),
          );
    }
    for (final (i, (method, amount)) in payments.indexed) {
      await db
          .into(db.salePayments)
          .insert(
            SalePaymentsCompanion.insert(
              id: '$id-p$i',
              saleId: id,
              method: method,
              amountTiyin: amount,
              receivedTiyin: Value(method == 'cash' ? amount : null),
            ),
          );
    }
  }

  await sale(
    's1',
    'D3-000001',
    DateTime.utc(2026, 10, 15, 5, 5),
    [
      ('p-non', 'Non', 2000, 800000),
      ('p-sut', 'Sut 1L', 1000, 1700000),
    ],
    [('cash', 2500000)],
  );
  await sale(
    's2',
    'D3-000002',
    DateTime.utc(2026, 10, 15, 6, 30),
    [('p-choy', 'Choy Ahmad', 2000, 4800000)],
    [('card', 3000000), ('debt', 1800000)],
    customerId: 'c1',
    status: 'partially_refunded',
  );
  await sale(
    's3',
    'D3-000003',
    DateTime.utc(2026, 10, 14, 13),
    [('p-olma', 'Olma', 1000, 1200000)],
    [('cash', 1200000)],
    status: 'refunded',
  );
  for (final (id, saleId, total, method, at) in [
    ('r1', 's2', 500000, 'debt', DateTime.utc(2026, 10, 15, 7)),
    ('r2', 's3', 1200000, 'cash', DateTime.utc(2026, 10, 14, 14)),
  ]) {
    await db
        .into(db.refunds)
        .insert(
          RefundsCompanion.insert(
            id: id,
            saleId: saleId,
            shiftId: 'shift-test',
            cashierId: 'cashier-1',
            method: method,
            totalTiyin: total,
            reason: const Value('Yaroqsiz'),
            at: at,
          ),
        );
  }
}
