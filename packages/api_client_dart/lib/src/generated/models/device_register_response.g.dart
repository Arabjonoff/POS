// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_register_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRegisterResponse _$DeviceRegisterResponseFromJson(
  Map<String, dynamic> json,
) => DeviceRegisterResponse(
  device: Device.fromJson(json['device'] as Map<String, dynamic>),
  token: json['token'] as String,
);

Map<String, dynamic> _$DeviceRegisterResponseToJson(
  DeviceRegisterResponse instance,
) => <String, dynamic>{
  'device': instance.device.toJson(),
  'token': instance.token,
};
