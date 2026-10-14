// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushResponse _$PushResponseFromJson(Map<String, dynamic> json) => PushResponse(
  results: (json['results'] as List<dynamic>)
      .map((e) => EventResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  serverTime: DateTime.parse(json['server_time'] as String),
);

Map<String, dynamic> _$PushResponseToJson(PushResponse instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
      'server_time': instance.serverTime.toIso8601String(),
    };
