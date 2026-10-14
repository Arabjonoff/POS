// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'role_enum.dart';
import 'tenant_brief.dart';

part 'me.g.dart';

@JsonSerializable()
class Me {
  const Me({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.tenant,
  });
  
  factory Me.fromJson(Map<String, Object?> json) => _$MeFromJson(json);
  
  final String id;
  final String? phone;
  @JsonKey(name: 'full_name')
  final String fullName;
  final RoleEnum role;
  final TenantBrief? tenant;

  Map<String, Object?> toJson() => _$MeToJson(this);
}
