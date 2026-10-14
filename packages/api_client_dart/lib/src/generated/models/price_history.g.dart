// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceHistory _$PriceHistoryFromJson(Map<String, dynamic> json) => PriceHistory(
  id: json['id'] as String,
  sellPriceTiyin: (json['sell_price_tiyin'] as num).toInt(),
  costPriceTiyin: (json['cost_price_tiyin'] as num).toInt(),
  changedBy: json['changed_by'] as String?,
  changedByName: json['changed_by_name'] as String?,
  at: DateTime.parse(json['at'] as String),
);

Map<String, dynamic> _$PriceHistoryToJson(PriceHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sell_price_tiyin': instance.sellPriceTiyin,
      'cost_price_tiyin': instance.costPriceTiyin,
      'changed_by': ?instance.changedBy,
      'changed_by_name': ?instance.changedByName,
      'at': instance.at.toIso8601String(),
    };
