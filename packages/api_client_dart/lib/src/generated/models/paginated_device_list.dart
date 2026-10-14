// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device.dart';

part 'paginated_device_list.g.dart';

@JsonSerializable()
class PaginatedDeviceList {
  const PaginatedDeviceList({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });
  
  factory PaginatedDeviceList.fromJson(Map<String, Object?> json) => _$PaginatedDeviceListFromJson(json);
  
  final int count;
  final String? next;
  final String? previous;
  final List<Device> results;

  Map<String, Object?> toJson() => _$PaginatedDeviceListToJson(this);
}
