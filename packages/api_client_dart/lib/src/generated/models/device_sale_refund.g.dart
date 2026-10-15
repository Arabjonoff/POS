// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_sale_refund.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceSaleRefund _$DeviceSaleRefundFromJson(Map<String, dynamic> json) =>
    DeviceSaleRefund(
      id: json['id'] as String,
      at: DateTime.parse(json['at'] as String),
      method: RefundMethodEnum.fromJson(json['method'] as String),
      totalTiyin: (json['total_tiyin'] as num).toInt(),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$DeviceSaleRefundToJson(DeviceSaleRefund instance) =>
    <String, dynamic>{
      'id': instance.id,
      'at': instance.at.toIso8601String(),
      'method': _$RefundMethodEnumEnumMap[instance.method]!,
      'total_tiyin': instance.totalTiyin,
      'reason': instance.reason,
    };

const _$RefundMethodEnumEnumMap = {
  RefundMethodEnum.cash: 'cash',
  RefundMethodEnum.debt: 'debt',
  RefundMethodEnum.$unknown: r'$unknown',
};
