// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockReport _$StockReportFromJson(Map<String, dynamic> json) => StockReport(
  stockValueTiyin: (json['stock_value_tiyin'] as num).toInt(),
  low: (json['low'] as List<dynamic>)
      .map((e) => StockRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  negative: (json['negative'] as List<dynamic>)
      .map((e) => StockRow.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StockReportToJson(StockReport instance) =>
    <String, dynamic>{
      'stock_value_tiyin': instance.stockValueTiyin,
      'low': instance.low.map((e) => e.toJson()).toList(),
      'negative': instance.negative.map((e) => e.toJson()).toList(),
    };
