// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'stock_row.g.dart';

@JsonSerializable()
class StockRow {
  const StockRow({
    required this.product,
    required this.name,
    required this.qtyMilli,
    required this.minStockMilli,
  });
  
  factory StockRow.fromJson(Map<String, Object?> json) => _$StockRowFromJson(json);
  
  final String product;
  final String name;
  @JsonKey(name: 'qty_milli')
  final int qtyMilli;
  @JsonKey(name: 'min_stock_milli')
  final int minStockMilli;

  Map<String, Object?> toJson() => _$StockRowToJson(this);
}
