// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_request_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushRequestRequest _$PushRequestRequestFromJson(Map<String, dynamic> json) =>
    PushRequestRequest(
      events: (json['events'] as List<dynamic>)
          .map((e) => EventRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PushRequestRequestToJson(PushRequestRequest instance) =>
    <String, dynamic>{
      'events': instance.events.map((e) => e.toJson()).toList(),
    };
