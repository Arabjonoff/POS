// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRegisterRequest _$DeviceRegisterRequestFromJson(
  Map<String, dynamic> json,
) => DeviceRegisterRequest(
  name: json['name'] as String,
  platform: PlatformEnum.fromJson(json['platform'] as String),
  appVersion: json['app_version'] as String? ?? '',
  id: json['id'] as String?,
  store: json['store'] as String?,
);

Map<String, dynamic> _$DeviceRegisterRequestToJson(
  DeviceRegisterRequest instance,
) => <String, dynamic>{
  'id': ?instance.id,
  'name': instance.name,
  'platform': _$PlatformEnumEnumMap[instance.platform]!,
  'app_version': instance.appVersion,
  'store': ?instance.store,
};

const _$PlatformEnumEnumMap = {
  PlatformEnum.windows: 'windows',
  PlatformEnum.android: 'android',
  PlatformEnum.ios: 'ios',
  PlatformEnum.$unknown: r'$unknown',
};
