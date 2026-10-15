// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hour_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HourRow _$HourRowFromJson(Map<String, dynamic> json) => HourRow(
  hour: (json['hour'] as num).toInt(),
  revenueTiyin: (json['revenue_tiyin'] as num).toInt(),
  salesCount: (json['sales_count'] as num).toInt(),
);

Map<String, dynamic> _$HourRowToJson(HourRow instance) => <String, dynamic>{
  'hour': instance.hour,
  'revenue_tiyin': instance.revenueTiyin,
  'sales_count': instance.salesCount,
};
