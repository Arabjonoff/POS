// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceReport _$DeviceReportFromJson(Map<String, dynamic> json) => DeviceReport(
  summary: Summary.fromJson(json['summary'] as Map<String, dynamic>),
  byDay: (json['by_day'] as List<dynamic>)
      .map((e) => DayRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  byHour: (json['by_hour'] as List<dynamic>)
      .map((e) => HourRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  topProducts: (json['top_products'] as List<dynamic>)
      .map((e) => ProductRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  cashiers: (json['cashiers'] as List<dynamic>)
      .map((e) => CashierRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  debts: Debts.fromJson(json['debts'] as Map<String, dynamic>),
  stock: StockReport.fromJson(json['stock'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DeviceReportToJson(DeviceReport instance) =>
    <String, dynamic>{
      'summary': instance.summary.toJson(),
      'by_day': instance.byDay.map((e) => e.toJson()).toList(),
      'by_hour': instance.byHour.map((e) => e.toJson()).toList(),
      'top_products': instance.topProducts.map((e) => e.toJson()).toList(),
      'cashiers': instance.cashiers.map((e) => e.toJson()).toList(),
      'debts': instance.debts.toJson(),
      'stock': instance.stock.toJson(),
    };
