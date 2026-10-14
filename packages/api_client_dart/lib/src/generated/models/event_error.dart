// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'event_error.g.dart';

@JsonSerializable()
class EventError {
  const EventError({
    required this.code,
    required this.message,
    required this.details,
  });
  
  factory EventError.fromJson(Map<String, Object?> json) => _$EventErrorFromJson(json);
  
  final String code;
  final String message;
  final dynamic details;

  Map<String, Object?> toJson() => _$EventErrorToJson(this);
}
