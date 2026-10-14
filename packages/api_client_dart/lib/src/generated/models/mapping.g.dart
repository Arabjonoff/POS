// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mapping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mapping _$MappingFromJson(Map<String, dynamic> json) => Mapping(
  name: (json['name'] as num?)?.toInt(),
  barcode: (json['barcode'] as num?)?.toInt(),
  category: (json['category'] as num?)?.toInt(),
  unit: (json['unit'] as num?)?.toInt(),
  sellPrice: (json['sell_price'] as num?)?.toInt(),
  costPrice: (json['cost_price'] as num?)?.toInt(),
  stock: (json['stock'] as num?)?.toInt(),
);

Map<String, dynamic> _$MappingToJson(Mapping instance) => <String, dynamic>{
  'name': ?instance.name,
  'barcode': ?instance.barcode,
  'category': ?instance.category,
  'unit': ?instance.unit,
  'sell_price': ?instance.sellPrice,
  'cost_price': ?instance.costPrice,
  'stock': ?instance.stock,
};
