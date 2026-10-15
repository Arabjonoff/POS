import 'package:pos_app/core/time/store_time_zone.dart';

/// Hisobot davri: do'kon kunlari (devor soati, `DateTime.utc(y, m, d)`),
/// ikkalasi ham kiradi (`reports-api.md`).
class ReportPeriod {
  ReportPeriod(this.from, this.to, {this.zone = StoreTimeZone.tashkent})
    : assert(!from.isAfter(to), 'from > to');

  final DateTime from;
  final DateTime to;
  final StoreTimeZone zone;

  int get dayCount => to.difference(from).inDays + 1;

  List<DateTime> get days => [
    for (var i = 0; i < dayCount; i++) from.add(Duration(days: i)),
  ];

  /// Birinchi kun boshlanishi (UTC moment).
  DateTime get start => from.subtract(zone.offset);

  /// Oxirgi kundan keyingi yarim tun (kirmaydi).
  DateTime get end => to.add(const Duration(days: 1)).subtract(zone.offset);

  /// Shu uzunlikdagi oldingi davr (bugun ↔ kecha, 7 kun ↔ oldingi 7 kun).
  ReportPeriod previous() {
    final length = Duration(days: dayCount);
    return ReportPeriod(from.subtract(length), to.subtract(length), zone: zone);
  }

  String get fromIso => _iso(from);
  String get toIso => _iso(to);

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class ReportSummary {
  const ReportSummary({
    required this.salesTotalTiyin,
    required this.refundsTotalTiyin,
    required this.revenueTiyin,
    required this.profitTiyin,
    required this.salesCount,
    required this.averageCheckTiyin,
    required this.paymentsTiyin,
    required this.refundsByMethodTiyin,
    required this.previousRevenueTiyin,
    required this.previousProfitTiyin,
    required this.previousSalesCount,
    this.revenueChangeBp,
    this.profitChangeBp,
  });

  final int salesTotalTiyin;
  final int refundsTotalTiyin;
  final int revenueTiyin;
  final int profitTiyin;
  final int salesCount;
  final int averageCheckTiyin;

  /// `cash` / `card` / `debt`.
  final Map<String, int> paymentsTiyin;

  /// `cash` / `debt`.
  final Map<String, int> refundsByMethodTiyin;
  final int previousRevenueTiyin;
  final int previousProfitTiyin;
  final int previousSalesCount;

  /// Bazis punkt (1% = 100); oldingi 0 bo'lsa `null`.
  final int? revenueChangeBp;
  final int? profitChangeBp;
}

class DayRow {
  const DayRow({
    required this.date,
    required this.revenueTiyin,
    required this.salesCount,
    required this.profitTiyin,
  });

  final DateTime date;
  final int revenueTiyin;
  final int salesCount;
  final int profitTiyin;
}

class HourRow {
  const HourRow({
    required this.hour,
    required this.revenueTiyin,
    required this.salesCount,
  });

  final int hour;
  final int revenueTiyin;
  final int salesCount;
}

class ProductReportRow {
  const ProductReportRow({
    required this.productId,
    required this.name,
    required this.qtyMilli,
    required this.revenueTiyin,
    required this.profitTiyin,
  });

  final String productId;
  final String name;
  final int qtyMilli;
  final int revenueTiyin;
  final int profitTiyin;
}

class CashierReportRow {
  const CashierReportRow({
    required this.cashierId,
    required this.fullName,
    required this.salesCount,
    required this.salesTotalTiyin,
    required this.refundsCount,
    required this.refundsTotalTiyin,
  });

  final String cashierId;
  final String fullName;
  final int salesCount;
  final int salesTotalTiyin;
  final int refundsCount;
  final int refundsTotalTiyin;
}

class DebtorRow {
  const DebtorRow({
    required this.customerId,
    required this.fullName,
    required this.phone,
    required this.balanceTiyin,
  });

  final String customerId;
  final String fullName;
  final String phone;
  final int balanceTiyin;
}

class StockRow {
  const StockRow({
    required this.productId,
    required this.name,
    required this.qtyMilli,
    required this.minStockMilli,
  });

  final String productId;
  final String name;
  final int qtyMilli;
  final int minStockMilli;
}

/// Hamma hisobotlar bitta davr uchun. [local] — server javob bermadi,
/// faqat shu kassa ma'lumoti (boshqa kassalar savdosi yo'q).
class Reports {
  const Reports({
    required this.period,
    required this.summary,
    required this.byDay,
    required this.byHour,
    required this.topProducts,
    required this.cashiers,
    required this.totalDebtTiyin,
    required this.debtorsCount,
    required this.topDebtors,
    required this.stockValueTiyin,
    required this.low,
    required this.negative,
    required this.local,
  });

  final ReportPeriod period;
  final ReportSummary summary;
  final List<DayRow> byDay;
  final List<HourRow> byHour;
  final List<ProductReportRow> topProducts;
  final List<CashierReportRow> cashiers;
  final int totalDebtTiyin;
  final int debtorsCount;
  final List<DebtorRow> topDebtors;
  final int stockValueTiyin;
  final List<StockRow> low;
  final List<StockRow> negative;
  final bool local;
}
