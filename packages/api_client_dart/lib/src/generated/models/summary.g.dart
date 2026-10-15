// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Summary _$SummaryFromJson(Map<String, dynamic> json) => Summary(
  period: Period.fromJson(json['period'] as Map<String, dynamic>),
  revenueTiyin: (json['revenue_tiyin'] as num).toInt(),
  salesTotalTiyin: (json['sales_total_tiyin'] as num).toInt(),
  refundsTotalTiyin: (json['refunds_total_tiyin'] as num).toInt(),
  salesCount: (json['sales_count'] as num).toInt(),
  averageCheckTiyin: (json['average_check_tiyin'] as num).toInt(),
  profitTiyin: (json['profit_tiyin'] as num).toInt(),
  paymentsTiyin: Payments.fromJson(
    json['payments_tiyin'] as Map<String, dynamic>,
  ),
  refundsTiyin: RefundsByMethod.fromJson(
    json['refunds_tiyin'] as Map<String, dynamic>,
  ),
  previous: Previous.fromJson(json['previous'] as Map<String, dynamic>),
  revenueChangeBp: (json['revenue_change_bp'] as num?)?.toInt(),
  profitChangeBp: (json['profit_change_bp'] as num?)?.toInt(),
);

Map<String, dynamic> _$SummaryToJson(Summary instance) => <String, dynamic>{
  'period': instance.period.toJson(),
  'revenue_tiyin': instance.revenueTiyin,
  'sales_total_tiyin': instance.salesTotalTiyin,
  'refunds_total_tiyin': instance.refundsTotalTiyin,
  'sales_count': instance.salesCount,
  'average_check_tiyin': instance.averageCheckTiyin,
  'profit_tiyin': instance.profitTiyin,
  'payments_tiyin': instance.paymentsTiyin.toJson(),
  'refunds_tiyin': instance.refundsTiyin.toJson(),
  'previous': instance.previous.toJson(),
  'revenue_change_bp': ?instance.revenueChangeBp,
  'profit_change_bp': ?instance.profitChangeBp,
};
