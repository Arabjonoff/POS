import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/reports/local_reports.dart';
import 'package:pos_app/data/reports/reports.dart';

import '../helpers/report_vectors.dart';
import '../helpers/sqlite.dart';

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

Future<AppDatabase> _seed() => seedReportVectors(openTestDatabase());

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
