// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'row_error.g.dart';

@JsonSerializable()
class RowError {
  const RowError({
    required this.row,
    required this.field,
    required this.code,
  });
  
  factory RowError.fromJson(Map<String, Object?> json) => _$RowErrorFromJson(json);
  
  final int row;
  final String field;
  final String code;

  Map<String, Object?> toJson() => _$RowErrorToJson(this);
}
