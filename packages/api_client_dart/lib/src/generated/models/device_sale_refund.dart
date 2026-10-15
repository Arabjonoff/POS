// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'refund_method_enum.dart';

part 'device_sale_refund.g.dart';

@JsonSerializable()
class DeviceSaleRefund {
  const DeviceSaleRefund({
    required this.id,
    required this.at,
    required this.method,
    required this.totalTiyin,
    required this.reason,
  });
  
  factory DeviceSaleRefund.fromJson(Map<String, Object?> json) => _$DeviceSaleRefundFromJson(json);
  
  final String id;
  final DateTime at;
  final RefundMethodEnum method;
  @JsonKey(name: 'total_tiyin')
  final int totalTiyin;
  final String reason;

  Map<String, Object?> toJson() => _$DeviceSaleRefundToJson(this);
}
