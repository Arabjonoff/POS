// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stock_row.dart';

part 'stock_report.g.dart';

@JsonSerializable()
class StockReport {
  const StockReport({
    required this.stockValueTiyin,
    required this.low,
    required this.negative,
  });
  
  factory StockReport.fromJson(Map<String, Object?> json) => _$StockReportFromJson(json);
  
  @JsonKey(name: 'stock_value_tiyin')
  final int stockValueTiyin;
  final List<StockRow> low;
  final List<StockRow> negative;

  Map<String, Object?> toJson() => _$StockReportToJson(this);
}
