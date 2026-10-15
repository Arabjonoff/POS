import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:pos_api_client/pos_api_client.dart' as api;
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/reports/local_reports.dart';
import 'package:pos_app/data/reports/reports.dart';

typedef ReportsFetcher = Future<Reports> Function(ReportPeriod period);

/// Server hisobotlari (`GET /api/v1/sync/reports/`, qurilma tokeni): barcha
/// kassalar. Xato — [ApiFailure] (oflayn: `network`).
final reportsFetcherProvider = Provider<ReportsFetcher>((ref) {
  final tokens = ref.watch(deviceTokenStoreProvider);
  final dio = ref.watch(dioFactoryProvider);
  return (period) async {
    final token = await tokens.read();
    if (token == null) throw const ApiFailure(ApiFailureKind.unauthorized);
    try {
      // Generatsiya qilingan klient sanani to'liq vaqt qilib yuboradi —
      // server esa `YYYY-MM-DD` kutadi.
      final response = await dio('Device $token').get<Map<String, dynamic>>(
        '/api/v1/sync/reports/',
        queryParameters: {'date_from': period.fromIso, 'date_to': period.toIso},
      );
      return reportsFromApi(period, api.DeviceReport.fromJson(response.data!));
    } on Object catch (e) {
      throw ApiFailure.from(e);
    }
  };
});

/// Onlayn — serverdan; javob bo'lmasa — lokal bazadan ([Reports.local]).
final FutureProviderFamily<Reports, ReportPeriod> reportsProvider =
    FutureProvider.autoDispose.family<Reports, ReportPeriod>((
      ref,
      period,
    ) async {
      final fetch = ref.read(reportsFetcherProvider);
      final local = LocalReports(ref.read(appDatabaseProvider));
      try {
        return await fetch(period);
      } on ApiFailure {
        return local.build(period);
      }
    });

Reports reportsFromApi(ReportPeriod period, api.DeviceReport r) {
  final s = r.summary;
  return Reports(
    period: period,
    summary: ReportSummary(
      salesTotalTiyin: s.salesTotalTiyin,
      refundsTotalTiyin: s.refundsTotalTiyin,
      revenueTiyin: s.revenueTiyin,
      profitTiyin: s.profitTiyin,
      salesCount: s.salesCount,
      averageCheckTiyin: s.averageCheckTiyin,
      paymentsTiyin: {
        'cash': s.paymentsTiyin.cash,
        'card': s.paymentsTiyin.card,
        'debt': s.paymentsTiyin.debt,
      },
      refundsByMethodTiyin: {
        'cash': s.refundsTiyin.cash,
        'debt': s.refundsTiyin.debt,
      },
      previousRevenueTiyin: s.previous.revenueTiyin,
      previousProfitTiyin: s.previous.profitTiyin,
      previousSalesCount: s.previous.salesCount,
      revenueChangeBp: s.revenueChangeBp,
      profitChangeBp: s.profitChangeBp,
    ),
    byDay: [
      for (final d in r.byDay)
        DayRow(
          date: DateTime.utc(d.date.year, d.date.month, d.date.day),
          revenueTiyin: d.revenueTiyin,
          salesCount: d.salesCount,
          profitTiyin: d.profitTiyin,
        ),
    ],
    byHour: [
      for (final h in r.byHour)
        HourRow(
          hour: h.hour,
          revenueTiyin: h.revenueTiyin,
          salesCount: h.salesCount,
        ),
    ],
    topProducts: [
      for (final p in r.topProducts)
        ProductReportRow(
          productId: p.product,
          name: p.name,
          qtyMilli: p.qtyMilli,
          revenueTiyin: p.revenueTiyin,
          profitTiyin: p.profitTiyin,
        ),
    ],
    cashiers: [
      for (final c in r.cashiers)
        CashierReportRow(
          cashierId: c.cashier,
          fullName: c.fullName,
          salesCount: c.salesCount,
          salesTotalTiyin: c.salesTotalTiyin,
          refundsCount: c.refundsCount,
          refundsTotalTiyin: c.refundsTotalTiyin,
        ),
    ],
    totalDebtTiyin: r.debts.totalDebtTiyin,
    debtorsCount: r.debts.debtorsCount,
    topDebtors: [
      for (final d in r.debts.top)
        DebtorRow(
          customerId: d.customer,
          fullName: d.fullName,
          phone: d.phone,
          balanceTiyin: d.balanceTiyin,
        ),
    ],
    stockValueTiyin: r.stock.stockValueTiyin,
    low: [for (final s in r.stock.low) _stock(s)],
    negative: [for (final s in r.stock.negative) _stock(s)],
    local: false,
  );
}

StockRow _stock(api.StockRow s) => StockRow(
  productId: s.product,
  name: s.name,
  qtyMilli: s.qtyMilli,
  minStockMilli: s.minStockMilli,
);
