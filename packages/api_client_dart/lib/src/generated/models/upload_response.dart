// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mapping.dart';

part 'upload_response.g.dart';

@JsonSerializable()
class UploadResponse {
  const UploadResponse({
    required this.id,
    required this.columns,
    required this.sample,
    required this.totalRows,
    required this.mapping,
  });
  
  factory UploadResponse.fromJson(Map<String, Object?> json) => _$UploadResponseFromJson(json);
  
  final String id;
  final List<String> columns;
  final List<List<String>> sample;
  @JsonKey(name: 'total_rows')
  final int totalRows;
  final Mapping mapping;

  Map<String, Object?> toJson() => _$UploadResponseToJson(this);
}
