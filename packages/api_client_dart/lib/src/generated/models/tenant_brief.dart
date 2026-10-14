// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'tenant_brief.g.dart';

@JsonSerializable()
class TenantBrief {
  const TenantBrief({
    required this.id,
    required this.name,
  });
  
  factory TenantBrief.fromJson(Map<String, Object?> json) => _$TenantBriefFromJson(json);
  
  final String id;
  final String name;

  Map<String, Object?> toJson() => _$TenantBriefToJson(this);
}
