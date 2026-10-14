// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventError _$EventErrorFromJson(Map<String, dynamic> json) => EventError(
  code: json['code'] as String,
  message: json['message'] as String,
  details: json['details'],
);

Map<String, dynamic> _$EventErrorToJson(EventError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': ?instance.details,
    };
