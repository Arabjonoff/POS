// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_row.g.dart';

@JsonSerializable()
class ProductRow {
  const ProductRow({
    required this.product,
    required this.name,
    required this.qtyMilli,
    required this.revenueTiyin,
    required this.profitTiyin,
  });
  
  factory ProductRow.fromJson(Map<String, Object?> json) => _$ProductRowFromJson(json);
  
  final String product;
  final String name;
  @JsonKey(name: 'qty_milli')
  final int qtyMilli;
  @JsonKey(name: 'revenue_tiyin')
  final int revenueTiyin;
  @JsonKey(name: 'profit_tiyin')
  final int profitTiyin;

  Map<String, Object?> toJson() => _$ProductRowToJson(this);
}
