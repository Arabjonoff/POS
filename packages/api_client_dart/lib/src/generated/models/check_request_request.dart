// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mapping_request.dart';

part 'check_request_request.g.dart';

@JsonSerializable()
class CheckRequestRequest {
  const CheckRequestRequest({
    required this.mapping,
  });
  
  factory CheckRequestRequest.fromJson(Map<String, Object?> json) => _$CheckRequestRequestFromJson(json);
  
  final MappingRequest mapping;

  Map<String, Object?> toJson() => _$CheckRequestRequestToJson(this);
}
