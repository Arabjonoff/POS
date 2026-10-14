// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'platform_enum.dart';

part 'device.g.dart';

@JsonSerializable()
class Device {
  const Device({
    required this.id,
    required this.number,
    required this.code,
    required this.name,
    required this.platform,
    required this.appVersion,
    required this.store,
    required this.isBlocked,
    required this.lastSyncAt,
    required this.lastSeenAt,
    required this.createdAt,
  });
  
  factory Device.fromJson(Map<String, Object?> json) => _$DeviceFromJson(json);
  
  final String id;
  final int number;
  final String code;
  final String name;
  final PlatformEnum platform;
  @JsonKey(name: 'app_version')
  final String appVersion;
  final String store;
  @JsonKey(name: 'is_blocked')
  final bool isBlocked;
  @JsonKey(name: 'last_sync_at')
  final DateTime? lastSyncAt;
  @JsonKey(name: 'last_seen_at')
  final DateTime? lastSeenAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$DeviceToJson(this);
}
