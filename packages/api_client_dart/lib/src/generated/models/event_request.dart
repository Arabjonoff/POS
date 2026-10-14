// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'event_request.g.dart';

@JsonSerializable()
class EventRequest {
  const EventRequest({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });
  
  factory EventRequest.fromJson(Map<String, Object?> json) => _$EventRequestFromJson(json);
  
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$EventRequestToJson(this);
}
