// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mapping_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MappingRequest _$MappingRequestFromJson(Map<String, dynamic> json) =>
    MappingRequest(
      name: (json['name'] as num?)?.toInt(),
      barcode: (json['barcode'] as num?)?.toInt(),
      category: (json['category'] as num?)?.toInt(),
      unit: (json['unit'] as num?)?.toInt(),
      sellPrice: (json['sell_price'] as num?)?.toInt(),
      costPrice: (json['cost_price'] as num?)?.toInt(),
      stock: (json['stock'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MappingRequestToJson(MappingRequest instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'barcode': ?instance.barcode,
      'category': ?instance.category,
      'unit': ?instance.unit,
      'sell_price': ?instance.sellPrice,
      'cost_price': ?instance.costPrice,
      'stock': ?instance.stock,
    };
