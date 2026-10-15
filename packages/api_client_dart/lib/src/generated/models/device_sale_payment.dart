// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sale_payment_method_enum.dart';

part 'device_sale_payment.g.dart';

@JsonSerializable()
class DeviceSalePayment {
  const DeviceSalePayment({
    required this.method,
    required this.amountTiyin,
    required this.receivedTiyin,
    required this.changeTiyin,
  });
  
  factory DeviceSalePayment.fromJson(Map<String, Object?> json) => _$DeviceSalePaymentFromJson(json);
  
  final SalePaymentMethodEnum method;
  @JsonKey(name: 'amount_tiyin')
  final int amountTiyin;
  @JsonKey(name: 'received_tiyin')
  final int? receivedTiyin;
  @JsonKey(name: 'change_tiyin')
  final int changeTiyin;

  Map<String, Object?> toJson() => _$DeviceSalePaymentToJson(this);
}
