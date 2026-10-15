import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/reports/reports.dart';
import 'package:pos_app/data/reports/reports_provider.dart';

import '../helpers/fake_server.dart';
import '../helpers/sqlite.dart';

Map<String, Object?> serverReport() => {
  'summary': {
    'period': {'date_from': '2026-10-15', 'date_to': '2026-10-15'},
    'revenue_tiyin': 9000000,
    'sales_total_tiyin': 10000000,
    'refunds_total_tiyin': 1000000,
    'sales_count': 4,
    'average_check_tiyin': 2500000,
    'profit_tiyin': 2000000,
    'payments_tiyin': {'cash': 6000000, 'card': 4000000, 'debt': 0},
    'refunds_tiyin': {'cash': 1000000, 'debt': 0},
    'previous': {
      'revenue_tiyin': 6000000,
      'profit_tiyin': 0,
      'sales_count': 3,
    },
    'revenue_change_bp': 5000,
    'profit_change_bp': null,
  },
  'by_day': [
    {
      'date': '2026-10-15',
      'revenue_tiyin': 9000000,
      'sales_count': 4,
      'profit_tiyin': 2000000,
    },
  ],
  'by_hour': [
    for (var h = 0; h < 24; h++)
      {'hour': h, 'revenue_tiyin': h == 9 ? 9000000 : 0, 'sales_count': 0},
  ],
  'top_products': [
    {
      'product': 'p1',
      'name': 'Non',
      'qty_milli': 3000,
      'revenue_tiyin': 1200000,
      'profit_tiyin': 300000,
    },
  ],
  'cashiers': [
    {
      'cashier': 'u1',
      'full_name': 'Aziza',
      'sales_count': 4,
      'sales_total_tiyin': 10000000,
      'refunds_count': 1,
      'refunds_total_tiyin': 1000000,
    },
  ],
  'debts': {
    'total_debt_tiyin': 500000,
    'debtors_count': 1,
    'top': [
      {
        'customer': 'c1',
        'full_name': 'Ali',
        'phone': '',
        'balance_tiyin': 500000,
      },
    ],
  },
  'stock': {
    'stock_value_tiyin': 7000000,
    'low': [
      {
        'product': 'p2',
        'name': 'Sut',
        'qty_milli': 1000,
        'min_stock_milli': 5000,
      },
    ],
    'negative': <Object>[],
  },
};

void main() {
  final period = ReportPeriod(
    DateTime.utc(2026, 10, 15),
    DateTime.utc(2026, 10, 15),
  );

  ProviderContainer container(FakeServer server) {
    final db = openTestDatabase();
    addTearDown(db.close);
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        dioFactoryProvider.overrideWithValue(server.dio),
        deviceTokenStoreProvider.overrideWithValue(
          MemoryDeviceTokenStore('tok'),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('online: all kassas from the server, dates as YYYY-MM-DD', () async {
    final server = FakeServer()
      ..on('GET /api/v1/sync/reports/', (_) => (200, serverReport()));
    final reports = await container(
      server,
    ).read(reportsProvider(period).future);
    expect(reports.local, isFalse);
    expect(reports.summary.revenueTiyin, 9000000);
    expect(reports.summary.revenueChangeBp, 5000);
    expect(reports.summary.profitChangeBp, isNull);
    expect(reports.summary.paymentsTiyin, {
      'cash': 6000000,
      'card': 4000000,
      'debt': 0,
    });
    expect(reports.byDay.single.date, DateTime.utc(2026, 10, 15));
    expect(reports.byHour[9].revenueTiyin, 9000000);
    expect(reports.topProducts.single.name, 'Non');
    expect(reports.cashiers.single.fullName, 'Aziza');
    expect(reports.topDebtors.single.balanceTiyin, 500000);
    expect(reports.low.single.name, 'Sut');
    final request = server.requests.single;
    expect(request.query, {'date_from': '2026-10-15', 'date_to': '2026-10-15'});
    expect(request.authorization, 'Device tok');
  });

  test('offline: falls back to this kassa only', () async {
    final server = FakeServer()..on('GET /api/v1/sync/reports/', (_) => null);
    final reports = await container(
      server,
    ).read(reportsProvider(period).future);
    expect(reports.local, isTrue);
    expect(reports.summary.salesCount, 0);
    expect(reports.byHour, hasLength(24));
  });

  test('server error also falls back to local', () async {
    final server = FakeServer()
      ..on(
        'GET /api/v1/sync/reports/',
        (_) => (500, {'error': <String, Object?>{}}),
      );
    final reports = await container(
      server,
    ).read(reportsProvider(period).future);
    expect(reports.local, isTrue);
  });
}
