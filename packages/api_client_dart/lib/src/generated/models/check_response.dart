// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'row_error.dart';

part 'check_response.g.dart';

@JsonSerializable()
class CheckResponse {
  const CheckResponse({
    required this.creates,
    required this.updates,
    required this.errorCount,
    required this.errors,
  });
  
  factory CheckResponse.fromJson(Map<String, Object?> json) => _$CheckResponseFromJson(json);
  
  final int creates;
  final int updates;
  @JsonKey(name: 'error_count')
  final int errorCount;
  final List<RowError> errors;

  Map<String, Object?> toJson() => _$CheckResponseToJson(this);
}
