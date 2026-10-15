// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'previous.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Previous _$PreviousFromJson(Map<String, dynamic> json) => Previous(
  revenueTiyin: (json['revenue_tiyin'] as num).toInt(),
  profitTiyin: (json['profit_tiyin'] as num).toInt(),
  salesCount: (json['sales_count'] as num).toInt(),
);

Map<String, dynamic> _$PreviousToJson(Previous instance) => <String, dynamic>{
  'revenue_tiyin': instance.revenueTiyin,
  'profit_tiyin': instance.profitTiyin,
  'sales_count': instance.salesCount,
};
