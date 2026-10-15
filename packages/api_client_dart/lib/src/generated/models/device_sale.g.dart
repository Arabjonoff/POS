// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceSale _$DeviceSaleFromJson(Map<String, dynamic> json) => DeviceSale(
  id: json['id'] as String,
  number: json['number'] as String,
  store: json['store'] as String,
  deviceNumber: (json['device_number'] as num).toInt(),
  cashier: json['cashier'] as String,
  cashierName: json['cashier_name'] as String,
  customer: json['customer'] as String?,
  customerName: json['customer_name'] as String?,
  subtotalTiyin: (json['subtotal_tiyin'] as num).toInt(),
  discountTiyin: (json['discount_tiyin'] as num).toInt(),
  totalTiyin: (json['total_tiyin'] as num).toInt(),
  status: SaleStatusEnum.fromJson(json['status'] as String),
  soldAt: DateTime.parse(json['sold_at'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => DeviceSaleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  payments: (json['payments'] as List<dynamic>)
      .map((e) => DeviceSalePayment.fromJson(e as Map<String, dynamic>))
      .toList(),
  refunds: (json['refunds'] as List<dynamic>)
      .map((e) => DeviceSaleRefund.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DeviceSaleToJson(DeviceSale instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'store': instance.store,
      'device_number': instance.deviceNumber,
      'cashier': instance.cashier,
      'cashier_name': instance.cashierName,
      'customer': ?instance.customer,
      'customer_name': ?instance.customerName,
      'subtotal_tiyin': instance.subtotalTiyin,
      'discount_tiyin': instance.discountTiyin,
      'total_tiyin': instance.totalTiyin,
      'status': _$SaleStatusEnumEnumMap[instance.status]!,
      'sold_at': instance.soldAt.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'payments': instance.payments.map((e) => e.toJson()).toList(),
      'refunds': instance.refunds.map((e) => e.toJson()).toList(),
    };

const _$SaleStatusEnumEnumMap = {
  SaleStatusEnum.completed: 'completed',
  SaleStatusEnum.partiallyRefunded: 'partially_refunded',
  SaleStatusEnum.refunded: 'refunded',
  SaleStatusEnum.$unknown: r'$unknown',
};
