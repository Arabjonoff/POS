// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_me.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceMe _$DeviceMeFromJson(Map<String, dynamic> json) => DeviceMe(
  device: Device.fromJson(json['device'] as Map<String, dynamic>),
  subscription: SubscriptionSnapshot.fromJson(
    json['subscription'] as Map<String, dynamic>,
  ),
  serverTime: DateTime.parse(json['server_time'] as String),
);

Map<String, dynamic> _$DeviceMeToJson(DeviceMe instance) => <String, dynamic>{
  'device': instance.device.toJson(),
  'subscription': instance.subscription.toJson(),
  'server_time': instance.serverTime.toIso8601String(),
};
