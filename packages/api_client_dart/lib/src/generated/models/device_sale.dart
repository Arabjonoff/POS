// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device_sale_item.dart';
import 'device_sale_payment.dart';
import 'device_sale_refund.dart';
import 'sale_status_enum.dart';

part 'device_sale.g.dart';

@JsonSerializable()
class DeviceSale {
  const DeviceSale({
    required this.id,
    required this.number,
    required this.store,
    required this.deviceNumber,
    required this.cashier,
    required this.cashierName,
    required this.customer,
    required this.customerName,
    required this.subtotalTiyin,
    required this.discountTiyin,
    required this.totalTiyin,
    required this.status,
    required this.soldAt,
    required this.items,
    required this.payments,
    required this.refunds,
  });
  
  factory DeviceSale.fromJson(Map<String, Object?> json) => _$DeviceSaleFromJson(json);
  
  final String id;
  final String number;
  final String store;
  @JsonKey(name: 'device_number')
  final int deviceNumber;
  final String cashier;
  @JsonKey(name: 'cashier_name')
  final String cashierName;
  final String? customer;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'subtotal_tiyin')
  final int subtotalTiyin;
  @JsonKey(name: 'discount_tiyin')
  final int discountTiyin;
  @JsonKey(name: 'total_tiyin')
  final int totalTiyin;
  final SaleStatusEnum status;
  @JsonKey(name: 'sold_at')
  final DateTime soldAt;
  final List<DeviceSaleItem> items;
  final List<DeviceSalePayment> payments;
  final List<DeviceSaleRefund> refunds;

  Map<String, Object?> toJson() => _$DeviceSaleToJson(this);
}
