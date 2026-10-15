import 'package:drift/drift.dart';
import 'package:pos_app/core/money/money.dart';
import 'package:pos_app/data/catalog/product_editor.dart' show stockQuery;
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/reports/reports.dart';

/// Hisobotlar lokal bazadan — server bilan bir xil formulalar
/// (`reports-api.md`, `apps/reports/services.py`). Faqat shu kassaning
/// savdolari: boshqa kassalarnikini server biladi.
class LocalReports {
  LocalReports(this._db);

  final AppDatabase _db;

  static const int topLimit = 20;
  static const int debtorsLimit = 10;

  Future<Reports> build(ReportPeriod period) async {
    final current = await _load(period);
    final previous = await _load(period.previous());
    final names = await _productNames();
    final debts = await _debts();
    final stock = await _stock();
    return Reports(
      period: period,
      summary: _summary(current, previous),
      byDay: _byDay(current),
      byHour: _byHour(current),
      topProducts: _topProducts(current, names),
      cashiers: await _cashiers(current),
      totalDebtTiyin: debts.$1,
      debtorsCount: debts.$2,
      topDebtors: debts.$3,
      stockValueTiyin: stock.$1,
      low: stock.$2,
      negative: stock.$3,
      local: true,
    );
  }

  Future<_PeriodData> _load(ReportPeriod period) async {
    final sales =
        await (_db.select(_db.sales)..where(
              (s) =>
                  s.soldAt.isBiggerOrEqualValue(period.start) &
                  s.soldAt.isSmallerThanValue(period.end),
            ))
            .get();
    final saleIds = [for (final s in sales) s.id];
    final items = saleIds.isEmpty
        ? <SaleItem>[]
        : await (_db.select(
            _db.saleItems,
          )..where((i) => i.saleId.isIn(saleIds))).get();
    final payments = saleIds.isEmpty
        ? <SalePayment>[]
        : await (_db.select(
            _db.salePayments,
          )..where((p) => p.saleId.isIn(saleIds))).get();
    final refunds =
        await (_db.select(_db.refunds)..where(
              (r) =>
                  r.at.isBiggerOrEqualValue(period.start) &
                  r.at.isSmallerThanValue(period.end),
            ))
            .get();
    final refundIds = [for (final r in refunds) r.id];
    final refundItems = refundIds.isEmpty
        ? <RefundItem>[]
        : await (_db.select(
            _db.refundItems,
          )..where((i) => i.refundId.isIn(refundIds))).get();
    // Qaytarilgan qatorning tannarxi — asl savdo qatoridan (boshqa davrda
    // bo'lishi mumkin).
    final soldItemIds = {for (final i in refundItems) i.saleItemId};
    final refundedSaleItems = soldItemIds.isEmpty
        ? <SaleItem>[]
        : await (_db.select(
            _db.saleItems,
          )..where((i) => i.id.isIn(soldItemIds))).get();
    return _PeriodData(
      period: period,
      sales: sales,
      items: items,
      payments: payments,
      refunds: refunds,
      refundItems: refundItems,
      saleItemsById: {for (final i in refundedSaleItems) i.id: i},
    );
  }

  ReportSummary _summary(_PeriodData current, _PeriodData previous) {
    final now = current.totals;
    final before = previous.totals;
    final count = now.salesCount;
    final payments = <String, int>{'cash': 0, 'card': 0, 'debt': 0};
    for (final p in current.payments) {
      payments.update(p.method, (v) => v + p.amountTiyin, ifAbsent: () => 0);
    }
    final refunds = <String, int>{'cash': 0, 'debt': 0};
    for (final r in current.refunds) {
      refunds.update(r.method, (v) => v + r.totalTiyin, ifAbsent: () => 0);
    }
    return ReportSummary(
      salesTotalTiyin: now.salesTotal,
      refundsTotalTiyin: now.refundsTotal,
      revenueTiyin: now.revenue,
      profitTiyin: now.profit,
      salesCount: count,
      averageCheckTiyin: count == 0
          ? 0
          : Money.mulDivHalfUp(now.salesTotal, 1, count),
      paymentsTiyin: payments,
      refundsByMethodTiyin: refunds,
      previousRevenueTiyin: before.revenue,
      previousProfitTiyin: before.profit,
      previousSalesCount: before.salesCount,
      revenueChangeBp: _changeBp(now.revenue, before.revenue),
      profitChangeBp: _changeBp(now.profit, before.profit),
    );
  }

  static int? _changeBp(int current, int previous) => previous == 0
      ? null
      : Money.mulDivHalfUp(current - previous, 10000, previous);

  List<DayRow> _byDay(_PeriodData data) {
    final zone = data.period.zone;
    DateTime dayOf(DateTime at) {
      final wall = zone.wallClock(at);
      return DateTime.utc(wall.year, wall.month, wall.day);
    }

    final revenue = <DateTime, int>{};
    final cost = <DateTime, int>{};
    final count = <DateTime, int>{};
    final soldAt = <String, DateTime>{};
    for (final s in data.sales) {
      final day = dayOf(s.soldAt);
      soldAt[s.id] = day;
      revenue.update(
        day,
        (v) => v + s.totalTiyin,
        ifAbsent: () => s.totalTiyin,
      );
      count.update(day, (v) => v + 1, ifAbsent: () => 1);
    }
    for (final i in data.items) {
      final c = Money.lineTotal(i.costTiyin, i.qtyMilli);
      cost.update(soldAt[i.saleId]!, (v) => v + c, ifAbsent: () => c);
    }
    final refundDay = <String, DateTime>{};
    for (final r in data.refunds) {
      final day = dayOf(r.at);
      refundDay[r.id] = day;
      revenue.update(
        day,
        (v) => v - r.totalTiyin,
        ifAbsent: () => -r.totalTiyin,
      );
    }
    for (final i in data.refundItems) {
      final c = data.returnedCost(i);
      cost.update(refundDay[i.refundId]!, (v) => v - c, ifAbsent: () => -c);
    }
    return [
      for (final day in data.period.days)
        DayRow(
          date: day,
          revenueTiyin: revenue[day] ?? 0,
          salesCount: count[day] ?? 0,
          profitTiyin: (revenue[day] ?? 0) - (cost[day] ?? 0),
        ),
    ];
  }

  List<HourRow> _byHour(_PeriodData data) {
    final zone = data.period.zone;
    final revenue = List.filled(24, 0);
    final count = List.filled(24, 0);
    for (final s in data.sales) {
      final hour = zone.wallClock(s.soldAt).hour;
      revenue[hour] += s.totalTiyin;
      count[hour] += 1;
    }
    for (final r in data.refunds) {
      revenue[zone.wallClock(r.at).hour] -= r.totalTiyin;
    }
    return [
      for (var h = 0; h < 24; h++)
        HourRow(hour: h, revenueTiyin: revenue[h], salesCount: count[h]),
    ];
  }

  List<ProductReportRow> _topProducts(
    _PeriodData data,
    Map<String, String> names,
  ) {
    final rows = <String, _ProductAcc>{};
    for (final i in data.items) {
      rows.putIfAbsent(i.productId, () => _ProductAcc(i.nameSnapshot))
        ..qty += i.qtyMilli
        ..total += i.totalTiyin
        ..cost += Money.lineTotal(i.costTiyin, i.qtyMilli);
    }
    final returned = <String, _ProductAcc>{};
    for (final i in data.refundItems) {
      final sold = data.saleItemsById[i.saleItemId];
      if (sold == null) continue;
      returned.putIfAbsent(sold.productId, () => _ProductAcc(''))
        ..qty += i.qtyMilli
        ..total += i.totalTiyin
        ..cost += data.returnedCost(i);
    }
    final result =
        [
          for (final MapEntry(key: id, value: acc) in rows.entries)
            () {
              final back = returned[id] ?? _ProductAcc('');
              final revenue = acc.total - back.total;
              return ProductReportRow(
                productId: id,
                name: names[id] ?? acc.name,
                qtyMilli: acc.qty - back.qty,
                revenueTiyin: revenue,
                profitTiyin: revenue - (acc.cost - back.cost),
              );
            }(),
        ]..sort((a, b) {
          final byRevenue = b.revenueTiyin.compareTo(a.revenueTiyin);
          return byRevenue != 0 ? byRevenue : b.name.compareTo(a.name);
        });
    return result.take(topLimit).toList();
  }

  Future<List<CashierReportRow>> _cashiers(_PeriodData data) async {
    final acc = <String, List<int>>{};
    for (final s in data.sales) {
      final row = acc.putIfAbsent(s.cashierId, () => [0, 0, 0, 0]);
      row[0] += 1;
      row[1] += s.totalTiyin;
    }
    for (final r in data.refunds) {
      final row = acc.putIfAbsent(r.cashierId, () => [0, 0, 0, 0]);
      row[2] += 1;
      row[3] += r.totalTiyin;
    }
    final staff = acc.isEmpty
        ? <StaffUser>[]
        : await (_db.select(
            _db.staffUsers,
          )..where((u) => u.id.isIn(acc.keys))).get();
    final names = {for (final u in staff) u.id: u.fullName};
    final rows =
        [
          for (final MapEntry(key: id, value: v) in acc.entries)
            CashierReportRow(
              cashierId: id,
              fullName: names[id] ?? '',
              salesCount: v[0],
              salesTotalTiyin: v[1],
              refundsCount: v[2],
              refundsTotalTiyin: v[3],
            ),
        ]..sort((a, b) {
          final byTotal = b.salesTotalTiyin.compareTo(a.salesTotalTiyin);
          return byTotal != 0 ? byTotal : a.fullName.compareTo(b.fullName);
        });
    return rows;
  }

  Future<Map<String, String>> _productNames() async {
    final products = await _db.select(_db.products).get();
    return {for (final p in products) p.id: p.name};
  }

  Future<(int, int, List<DebtorRow>)> _debts() async {
    final debtors =
        [
          for (final c in await CustomerDirectory(_db).all())
            if (c.balanceTiyin > 0) c,
        ]..sort((a, b) {
          final byBalance = b.balanceTiyin.compareTo(a.balanceTiyin);
          return byBalance != 0 ? byBalance : a.id.compareTo(b.id);
        });
    return (
      debtors.fold<int>(0, (s, c) => s + c.balanceTiyin),
      debtors.length,
      [
        for (final c in debtors.take(debtorsLimit))
          DebtorRow(
            customerId: c.id,
            fullName: c.name,
            phone: c.phone,
            balanceTiyin: c.balanceTiyin,
          ),
      ],
    );
  }

  Future<(int, List<StockRow>, List<StockRow>)> _stock() async {
    final qty = Map.fromEntries(await stockQuery(_db).get());
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.deletedAt.isNull())).get();
    var value = 0;
    final low = <StockRow>[];
    final negative = <StockRow>[];
    for (final p in products) {
      final q = qty[p.id] ?? 0;
      if (q > 0) value += Money.lineTotal(p.costPriceTiyin, q);
      if (!p.isActive) continue;
      final row = StockRow(
        productId: p.id,
        name: p.name,
        qtyMilli: q,
        minStockMilli: p.minStockMilli,
      );
      if (p.minStockMilli > 0 && q < p.minStockMilli) low.add(row);
      if (q < 0) negative.add(row);
    }
    low.sort((a, b) => a.name.compareTo(b.name));
    negative.sort((a, b) {
      final byQty = a.qtyMilli.compareTo(b.qtyMilli);
      return byQty != 0 ? byQty : a.name.compareTo(b.name);
    });
    return (value, low, negative);
  }
}

class _ProductAcc {
  _ProductAcc(this.name);

  final String name;
  int qty = 0;
  int total = 0;
  int cost = 0;
}

class _Totals {
  const _Totals({
    required this.salesTotal,
    required this.refundsTotal,
    required this.salesCount,
    required this.soldCost,
    required this.returnedCost,
  });

  final int salesTotal;
  final int refundsTotal;
  final int salesCount;
  final int soldCost;
  final int returnedCost;

  int get revenue => salesTotal - refundsTotal;

  /// Q-004: chek chegirmasi va qaytarishlar bilan.
  int get profit => revenue - soldCost + returnedCost;
}

class _PeriodData {
  _PeriodData({
    required this.period,
    required this.sales,
    required this.items,
    required this.payments,
    required this.refunds,
    required this.refundItems,
    required this.saleItemsById,
  });

  final ReportPeriod period;
  final List<Sale> sales;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final List<Refund> refunds;
  final List<RefundItem> refundItems;
  final Map<String, SaleItem> saleItemsById;

  int returnedCost(RefundItem item) {
    final sold = saleItemsById[item.saleItemId];
    return sold == null ? 0 : Money.lineTotal(sold.costTiyin, item.qtyMilli);
  }

  late final _Totals totals = _Totals(
    salesTotal: sales.fold(0, (s, e) => s + e.totalTiyin),
    refundsTotal: refunds.fold(0, (s, e) => s + e.totalTiyin),
    salesCount: sales.length,
    soldCost: items.fold(
      0,
      (s, e) => s + Money.lineTotal(e.costTiyin, e.qtyMilli),
    ),
    returnedCost: refundItems.fold(0, (s, e) => s + returnedCost(e)),
  );
}
