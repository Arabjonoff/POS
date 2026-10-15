import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/reports/local_reports.dart';
import 'package:pos_app/data/reports/reports.dart';

import '../helpers/sqlite.dart';

final Map<String, dynamic> vectors =
    jsonDecode(File('../../testdata/report_vectors.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> rows(Object? value) =>
    (value! as List<dynamic>).cast<Map<String, dynamic>>();

DateTime _date(String iso) {
  final d = DateTime.parse(iso);
  return DateTime.utc(d.year, d.month, d.day);
}

ReportPeriod _period() {
  final p = vectors['period'] as Map<String, dynamic>;
  return ReportPeriod(
    _date(p['date_from'] as String),
    _date(p['date_to'] as String),
  );
}

/// Umumiy vektorlarni lokal jadvallarga yozadi (server testi bilan bir xil).
Future<AppDatabase> _seed() async {
  final db = openTestDatabase();
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

void main() {
  final expected = vectors['expected'] as Map<String, dynamic>;

  test('summary matches shared vectors', () async {
    final db = await _seed();
    addTearDown(db.close);
    final reports = await LocalReports(db).build(_period());
    final s = reports.summary;
    final e = expected['summary'] as Map<String, dynamic>;
    final previous = e['previous'] as Map<String, dynamic>;
    expect(
      {
        'sales_total_tiyin': s.salesTotalTiyin,
        'refunds_total_tiyin': s.refundsTotalTiyin,
        'revenue_tiyin': s.revenueTiyin,
        'profit_tiyin': s.profitTiyin,
        'sales_count': s.salesCount,
        'average_check_tiyin': s.averageCheckTiyin,
        'payments_tiyin': s.paymentsTiyin,
        'refunds_tiyin': s.refundsByMethodTiyin,
        'previous': {
          'revenue_tiyin': s.previousRevenueTiyin,
          'profit_tiyin': s.previousProfitTiyin,
          'sales_count': s.previousSalesCount,
        },
        'revenue_change_bp': s.revenueChangeBp,
        'profit_change_bp': s.profitChangeBp,
      },
      {...e, 'previous': previous},
    );
    expect(reports.local, isTrue);
  });

  test('by day, by hour, top products and cashiers match', () async {
    final db = await _seed();
    addTearDown(db.close);
    final reports = await LocalReports(db).build(_period());
    expect(
      [
        for (final d in reports.byDay)
          {
            'date': ReportPeriod(d.date, d.date).fromIso,
            'revenue_tiyin': d.revenueTiyin,
            'sales_count': d.salesCount,
            'profit_tiyin': d.profitTiyin,
          },
      ],
      expected['by_day'],
    );
    expect(reports.byHour, hasLength(24));
    expect(
      [
        for (final h in reports.byHour)
          if (h.revenueTiyin != 0 || h.salesCount != 0)
            {
              'hour': h.hour,
              'revenue_tiyin': h.revenueTiyin,
              'sales_count': h.salesCount,
            },
      ],
      expected['by_hour_nonzero'],
    );
    expect(
      [
        for (final p in reports.topProducts)
          {
            'name': p.name,
            'qty_milli': p.qtyMilli,
            'revenue_tiyin': p.revenueTiyin,
            'profit_tiyin': p.profitTiyin,
          },
      ],
      expected['top_products'],
    );
    expect(
      [
        for (final c in reports.cashiers)
          {
            'full_name': c.fullName,
            'sales_count': c.salesCount,
            'sales_total_tiyin': c.salesTotalTiyin,
            'refunds_count': c.refundsCount,
            'refunds_total_tiyin': c.refundsTotalTiyin,
          },
      ],
      expected['cashiers'],
    );
  });

  test('multi-day period: previous period has the same length', () {
    final p = ReportPeriod(
      DateTime.utc(2026, 10, 9),
      DateTime.utc(2026, 10, 15),
    );
    final prev = p.previous();
    expect((prev.fromIso, prev.toIso), ('2026-10-02', '2026-10-08'));
    expect(p.start, DateTime.utc(2026, 10, 8, 19));
    expect(p.end, DateTime.utc(2026, 10, 15, 19));
  });

  test('debts and stock: debtors by balance, low and negative', () async {
    final db = await _seed();
    addTearDown(db.close);
    final at = DateTime.utc(2026, 10, 2);
    final [non, olma, sut] = [
      for (final p in rows(vectors['products'])) p['id'] as String,
    ];
    await db.batch((b) {
      b
        ..insertAll(db.customers, [
          CustomersCompanion.insert(id: 'c1', fullName: 'Ali'),
          CustomersCompanion.insert(id: 'c2', fullName: 'Vali'),
          CustomersCompanion.insert(id: 'c3', fullName: 'Gani'),
        ])
        ..insertAll(db.debtEntries, [
          DebtEntriesCompanion.insert(
            id: 'd1',
            customerId: 'c1',
            amountTiyin: 100000,
            type: 'sale',
            at: at,
          ),
          DebtEntriesCompanion.insert(
            id: 'd2',
            customerId: 'c2',
            amountTiyin: 500000,
            type: 'sale',
            at: at,
          ),
          DebtEntriesCompanion.insert(
            id: 'd3',
            customerId: 'c3',
            amountTiyin: 0,
            type: 'sale',
            at: at,
          ),
        ])
        ..insertAll(db.productStock, [
          ProductStockCompanion.insert(
            productId: non,
            storeId: 's',
            qtyMilli: 2500,
            updatedAt: at,
          ),
          ProductStockCompanion.insert(
            productId: olma,
            storeId: 's',
            qtyMilli: -1000,
            updatedAt: at,
          ),
          ProductStockCompanion.insert(
            productId: sut,
            storeId: 's',
            qtyMilli: 1000,
            updatedAt: at,
          ),
        ])
        ..update(
          db.products,
          const ProductsCompanion(minStockMilli: Value(5000)),
          where: (p) => p.id.equals(sut),
        );
    });
    final reports = await LocalReports(db).build(_period());
    expect(reports.totalDebtTiyin, 600000);
    expect(reports.debtorsCount, 2);
    expect([for (final d in reports.topDebtors) d.fullName], ['Vali', 'Ali']);
    // Non 2,5 × 3 000 + Sut 1 × 9 500 (manfiy qoldiq hisoblanmaydi).
    expect(reports.stockValueTiyin, 750000 + 950000);
    expect([for (final r in reports.low) r.name], ['Sut']);
    expect([for (final r in reports.negative) r.name], ['Olma']);
  });
}
