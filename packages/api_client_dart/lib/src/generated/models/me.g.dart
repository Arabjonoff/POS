// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Me _$MeFromJson(Map<String, dynamic> json) => Me(
  id: json['id'] as String,
  phone: json['phone'] as String?,
  fullName: json['full_name'] as String,
  role: RoleEnum.fromJson(json['role'] as String),
  tenant: json['tenant'] == null
      ? null
      : TenantBrief.fromJson(json['tenant'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MeToJson(Me instance) => <String, dynamic>{
  'id': instance.id,
  'phone': ?instance.phone,
  'full_name': instance.fullName,
  'role': _$RoleEnumEnumMap[instance.role]!,
  'tenant': ?instance.tenant?.toJson(),
};

const _$RoleEnumEnumMap = {
  RoleEnum.platformAdmin: 'platform_admin',
  RoleEnum.owner: 'owner',
  RoleEnum.manager: 'manager',
  RoleEnum.cashier: 'cashier',
  RoleEnum.$unknown: r'$unknown',
};
