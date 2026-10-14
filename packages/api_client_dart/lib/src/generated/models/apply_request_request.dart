// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mapping_request.dart';

part 'apply_request_request.g.dart';

@JsonSerializable()
class ApplyRequestRequest {
  const ApplyRequestRequest({
    required this.mapping,
    required this.by,
  });
  
  factory ApplyRequestRequest.fromJson(Map<String, Object?> json) => _$ApplyRequestRequestFromJson(json);
  
  final MappingRequest mapping;
  final String by;

  Map<String, Object?> toJson() => _$ApplyRequestRequestToJson(this);
}
