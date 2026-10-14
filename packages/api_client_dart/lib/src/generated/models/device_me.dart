// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device.dart';
import 'subscription_snapshot.dart';

part 'device_me.g.dart';

@JsonSerializable()
class DeviceMe {
  const DeviceMe({
    required this.device,
    required this.subscription,
    required this.serverTime,
  });
  
  factory DeviceMe.fromJson(Map<String, Object?> json) => _$DeviceMeFromJson(json);
  
  final Device device;
  final SubscriptionSnapshot subscription;
  @JsonKey(name: 'server_time')
  final DateTime serverTime;

  Map<String, Object?> toJson() => _$DeviceMeToJson(this);
}
