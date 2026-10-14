// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventRequest _$EventRequestFromJson(Map<String, dynamic> json) => EventRequest(
  id: json['id'] as String,
  type: json['type'] as String,
  payload: json['payload'] as Map<String, dynamic>,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$EventRequestToJson(EventRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'payload': instance.payload,
      'created_at': instance.createdAt.toIso8601String(),
    };
