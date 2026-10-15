// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashier_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashierRow _$CashierRowFromJson(Map<String, dynamic> json) => CashierRow(
  cashier: json['cashier'] as String,
  fullName: json['full_name'] as String,
  salesCount: (json['sales_count'] as num).toInt(),
  salesTotalTiyin: (json['sales_total_tiyin'] as num).toInt(),
  refundsCount: (json['refunds_count'] as num).toInt(),
  refundsTotalTiyin: (json['refunds_total_tiyin'] as num).toInt(),
);

Map<String, dynamic> _$CashierRowToJson(CashierRow instance) =>
    <String, dynamic>{
      'cashier': instance.cashier,
      'full_name': instance.fullName,
      'sales_count': instance.salesCount,
      'sales_total_tiyin': instance.salesTotalTiyin,
      'refunds_count': instance.refundsCount,
      'refunds_total_tiyin': instance.refundsTotalTiyin,
    };
