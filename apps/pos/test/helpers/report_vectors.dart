import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:pos_app/data/db/app_database.dart';

/// Umumiy hisobot vektorlari (`testdata/report_vectors.json`): server testi
/// bilan bir xil ma'lumot.
final Map<String, dynamic> vectors =
    jsonDecode(File('../../testdata/report_vectors.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> rows(Object? value) =>
    (value! as List<dynamic>).cast<Map<String, dynamic>>();

/// Umumiy vektorlarni lokal jadvallarga yozadi (server testi bilan bir xil).
Future<AppDatabase> seedReportVectors(AppDatabase db) async {
  await db.batch((b) {
    b
      ..insert(
        db.shifts,
        ShiftsCompanion.insert(
          id: 'shift-1',
          storeId: 'store-1',
          deviceId: 'device-1',
          openedBy: 'x',
          openedAt: DateTime.utc(2026, 10, 14, 1),
          openingCashTiyin: 0,
        ),
      )
      ..insertAll(db.staffUsers, [
        for (final c in rows(vectors['cashiers']))
          StaffUsersCompanion.insert(
            id: c['id'] as String,
            fullName: c['name'] as String,
            role: 'cashier',
          ),
      ])
      ..insertAll(db.units, [
        UnitsCompanion.insert(id: 'pcs', code: 'pcs'),
        UnitsCompanion.insert(
          id: 'kg',
          code: 'kg',
          isFractional: const Value(true),
        ),
      ])
      ..insertAll(db.products, [
        for (final p in rows(vectors['products']))
          ProductsCompanion.insert(
            id: p['id'] as String,
            name: p['name'] as String,
            unitId: p['unit'] as String,
            sellPriceTiyin: p['price'] as int,
            costPriceTiyin: Value(p['cost'] as int),
          ),
      ]);
    for (final s in rows(vectors['sales'])) {
      b
        ..insert(
          db.sales,
          SalesCompanion.insert(
            id: s['id'] as String,
            shiftId: 'shift-1',
            cashierId: s['cashier'] as String,
            number: s['number'] as String,
            subtotalTiyin: s['subtotal'] as int,
            discountTiyin: s['discount'] as int,
            totalTiyin: s['total'] as int,
            soldAt: DateTime.parse(s['sold_at'] as String),
          ),
        )
        ..insertAll(db.saleItems, [
          for (final (n, i) in rows(s['items']).indexed)
            SaleItemsCompanion.insert(
              id: i['id'] as String,
              saleId: s['id'] as String,
              position: n,
              productId: i['product'] as String,
              nameSnapshot: i['name'] as String,
              qtyMilli: i['qty'] as int,
              priceTiyin: i['price'] as int,
              costTiyin: i['cost'] as int,
              discountTiyin: i['discount'] as int,
              totalTiyin: i['total'] as int,
            ),
        ])
        ..insertAll(db.salePayments, [
          for (final p in rows(s['payments']))
            SalePaymentsCompanion.insert(
              id: p['id'] as String,
              saleId: s['id'] as String,
              method: p['method'] as String,
              amountTiyin: p['amount'] as int,
            ),
        ]);
    }
    for (final r in rows(vectors['refunds'])) {
      b
        ..insert(
          db.refunds,
          RefundsCompanion.insert(
            id: r['id'] as String,
            saleId: r['sale'] as String,
            shiftId: 'shift-1',
            cashierId: r['cashier'] as String,
            method: r['method'] as String,
            totalTiyin: r['total'] as int,
            at: DateTime.parse(r['at'] as String),
          ),
        )
        ..insertAll(db.refundItems, [
          for (final i in rows(r['items']))
            RefundItemsCompanion.insert(
              id: i['id'] as String,
              refundId: r['id'] as String,
              saleItemId: i['sale_item'] as String,
              qtyMilli: i['qty'] as int,
              totalTiyin: i['total'] as int,
            ),
        ]);
    }
  });
  return db;
}
