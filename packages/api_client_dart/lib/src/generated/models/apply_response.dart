// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'row_error.dart';

part 'apply_response.g.dart';

@JsonSerializable()
class ApplyResponse {
  const ApplyResponse({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errorCount,
    required this.errors,
    required this.receipt,
  });
  
  factory ApplyResponse.fromJson(Map<String, Object?> json) => _$ApplyResponseFromJson(json);
  
  final int created;
  final int updated;
  final int skipped;
  @JsonKey(name: 'error_count')
  final int errorCount;
  final List<RowError> errors;
  final int? receipt;

  Map<String, Object?> toJson() => _$ApplyResponseToJson(this);
}
