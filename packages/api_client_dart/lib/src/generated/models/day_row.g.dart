// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayRow _$DayRowFromJson(Map<String, dynamic> json) => DayRow(
  date: DateTime.parse(json['date'] as String),
  revenueTiyin: (json['revenue_tiyin'] as num).toInt(),
  salesCount: (json['sales_count'] as num).toInt(),
  profitTiyin: (json['profit_tiyin'] as num).toInt(),
);

Map<String, dynamic> _$DayRowToJson(DayRow instance) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'revenue_tiyin': instance.revenueTiyin,
  'sales_count': instance.salesCount,
  'profit_tiyin': instance.profitTiyin,
};
