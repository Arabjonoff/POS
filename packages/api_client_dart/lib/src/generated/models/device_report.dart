// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cashier_row.dart';
import 'day_row.dart';
import 'debts.dart';
import 'hour_row.dart';
import 'product_row.dart';
import 'stock_report.dart';
import 'summary.dart';

part 'device_report.g.dart';

/// Kassa uchun bitta so'rovda hamma hisobotlar (T-070).
@JsonSerializable()
class DeviceReport {
  const DeviceReport({
    required this.summary,
    required this.byDay,
    required this.byHour,
    required this.topProducts,
    required this.cashiers,
    required this.debts,
    required this.stock,
  });
  
  factory DeviceReport.fromJson(Map<String, Object?> json) => _$DeviceReportFromJson(json);
  
  final Summary summary;
  @JsonKey(name: 'by_day')
  final List<DayRow> byDay;
  @JsonKey(name: 'by_hour')
  final List<HourRow> byHour;
  @JsonKey(name: 'top_products')
  final List<ProductRow> topProducts;
  final List<CashierRow> cashiers;
  final Debts debts;
  final StockReport stock;

  Map<String, Object?> toJson() => _$DeviceReportToJson(this);
}
