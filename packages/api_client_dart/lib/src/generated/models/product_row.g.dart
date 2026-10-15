// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductRow _$ProductRowFromJson(Map<String, dynamic> json) => ProductRow(
  product: json['product'] as String,
  name: json['name'] as String,
  qtyMilli: (json['qty_milli'] as num).toInt(),
  revenueTiyin: (json['revenue_tiyin'] as num).toInt(),
  profitTiyin: (json['profit_tiyin'] as num).toInt(),
);

Map<String, dynamic> _$ProductRowToJson(ProductRow instance) =>
    <String, dynamic>{
      'product': instance.product,
      'name': instance.name,
      'qty_milli': instance.qtyMilli,
      'revenue_tiyin': instance.revenueTiyin,
      'profit_tiyin': instance.profitTiyin,
    };
