// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Change _$ChangeFromJson(Map<String, dynamic> json) => Change(
  entity: json['entity'] as String,
  op: OpEnum.fromJson(json['op'] as String),
  id: json['id'] as String,
  data: json['data'],
);

Map<String, dynamic> _$ChangeToJson(Change instance) => <String, dynamic>{
  'entity': instance.entity,
  'op': _$OpEnumEnumMap[instance.op]!,
  'id': instance.id,
  'data': ?instance.data,
};

const _$OpEnumEnumMap = {
  OpEnum.upsert: 'upsert',
  OpEnum.delete: 'delete',
  OpEnum.$unknown: r'$unknown',
};
