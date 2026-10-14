// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'event_error.dart';
import 'event_result_status_enum.dart';

part 'event_result.g.dart';

@JsonSerializable()
class EventResult {
  const EventResult({
    required this.id,
    required this.status,
    this.error,
  });
  
  factory EventResult.fromJson(Map<String, Object?> json) => _$EventResultFromJson(json);
  
  final String id;
  final EventResultStatusEnum status;
  final EventError? error;

  Map<String, Object?> toJson() => _$EventResultToJson(this);
}
