// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventResult _$EventResultFromJson(Map<String, dynamic> json) => EventResult(
  id: json['id'] as String,
  status: EventResultStatusEnum.fromJson(json['status'] as String),
  error: json['error'] == null
      ? null
      : EventError.fromJson(json['error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EventResultToJson(EventResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$EventResultStatusEnumEnumMap[instance.status]!,
      'error': ?instance.error?.toJson(),
    };

const _$EventResultStatusEnumEnumMap = {
  EventResultStatusEnum.applied: 'applied',
  EventResultStatusEnum.duplicate: 'duplicate',
  EventResultStatusEnum.pending: 'pending',
  EventResultStatusEnum.rejected: 'rejected',
  EventResultStatusEnum.$unknown: r'$unknown',
};
