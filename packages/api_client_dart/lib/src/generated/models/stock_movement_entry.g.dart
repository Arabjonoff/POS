// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockMovementEntry _$StockMovementEntryFromJson(Map<String, dynamic> json) =>
    StockMovementEntry(
      id: json['id'] as String,
      type: StockMovementTypeEnum.fromJson(json['type'] as String),
      qtyMilli: (json['qty_milli'] as num).toInt(),
      refType: json['ref_type'] as String,
      at: DateTime.parse(json['at'] as String),
      createdByName: json['created_by_name'] as String?,
    );

Map<String, dynamic> _$StockMovementEntryToJson(StockMovementEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$StockMovementTypeEnumEnumMap[instance.type]!,
      'qty_milli': instance.qtyMilli,
      'ref_type': instance.refType,
      'at': instance.at.toIso8601String(),
      'created_by_name': ?instance.createdByName,
    };

const _$StockMovementTypeEnumEnumMap = {
  StockMovementTypeEnum.receipt: 'receipt',
  StockMovementTypeEnum.sale: 'sale',
  StockMovementTypeEnum.refund: 'refund',
  StockMovementTypeEnum.adjustment: 'adjustment',
  StockMovementTypeEnum.inventory: 'inventory',
  StockMovementTypeEnum.$unknown: r'$unknown',
};
