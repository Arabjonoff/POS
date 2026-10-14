// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'event_request.dart';

part 'push_request_request.g.dart';

@JsonSerializable()
class PushRequestRequest {
  const PushRequestRequest({
    required this.events,
  });
  
  factory PushRequestRequest.fromJson(Map<String, Object?> json) => _$PushRequestRequestFromJson(json);
  
  final List<EventRequest> events;

  Map<String, Object?> toJson() => _$PushRequestRequestToJson(this);
}
