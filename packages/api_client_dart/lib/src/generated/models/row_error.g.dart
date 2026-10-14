// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'row_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RowError _$RowErrorFromJson(Map<String, dynamic> json) => RowError(
  row: (json['row'] as num).toInt(),
  field: json['field'] as String,
  code: json['code'] as String,
);

Map<String, dynamic> _$RowErrorToJson(RowError instance) => <String, dynamic>{
  'row': instance.row,
  'field': instance.field,
  'code': instance.code,
};
