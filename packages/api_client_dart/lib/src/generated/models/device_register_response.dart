// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device.dart';

part 'device_register_response.g.dart';

@JsonSerializable()
class DeviceRegisterResponse {
  const DeviceRegisterResponse({
    required this.device,
    required this.token,
  });
  
  factory DeviceRegisterResponse.fromJson(Map<String, Object?> json) => _$DeviceRegisterResponseFromJson(json);
  
  final Device device;
  final String token;

  Map<String, Object?> toJson() => _$DeviceRegisterResponseToJson(this);
}
