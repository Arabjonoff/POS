// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockRow _$StockRowFromJson(Map<String, dynamic> json) => StockRow(
  product: json['product'] as String,
  name: json['name'] as String,
  qtyMilli: (json['qty_milli'] as num).toInt(),
  minStockMilli: (json['min_stock_milli'] as num).toInt(),
);

Map<String, dynamic> _$StockRowToJson(StockRow instance) => <String, dynamic>{
  'product': instance.product,
  'name': instance.name,
  'qty_milli': instance.qtyMilli,
  'min_stock_milli': instance.minStockMilli,
};
