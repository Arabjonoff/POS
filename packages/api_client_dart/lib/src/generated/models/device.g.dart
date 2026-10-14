// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
  id: json['id'] as String,
  number: (json['number'] as num).toInt(),
  code: json['code'] as String,
  name: json['name'] as String,
  platform: PlatformEnum.fromJson(json['platform'] as String),
  appVersion: json['app_version'] as String,
  store: json['store'] as String,
  isBlocked: json['is_blocked'] as bool,
  lastSyncAt: json['last_sync_at'] == null
      ? null
      : DateTime.parse(json['last_sync_at'] as String),
  lastSeenAt: json['last_seen_at'] == null
      ? null
      : DateTime.parse(json['last_seen_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'code': instance.code,
  'name': instance.name,
  'platform': _$PlatformEnumEnumMap[instance.platform]!,
  'app_version': instance.appVersion,
  'store': instance.store,
  'is_blocked': instance.isBlocked,
  'last_sync_at': ?instance.lastSyncAt?.toIso8601String(),
  'last_seen_at': ?instance.lastSeenAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

const _$PlatformEnumEnumMap = {
  PlatformEnum.windows: 'windows',
  PlatformEnum.android: 'android',
  PlatformEnum.ios: 'ios',
  PlatformEnum.$unknown: r'$unknown',
};
