// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Period _$PeriodFromJson(Map<String, dynamic> json) => Period(
  dateFrom: DateTime.parse(json['date_from'] as String),
  dateTo: DateTime.parse(json['date_to'] as String),
);

Map<String, dynamic> _$PeriodToJson(Period instance) => <String, dynamic>{
  'date_from': instance.dateFrom.toIso8601String(),
  'date_to': instance.dateTo.toIso8601String(),
};
