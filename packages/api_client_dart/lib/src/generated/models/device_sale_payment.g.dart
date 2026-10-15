// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_sale_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceSalePayment _$DeviceSalePaymentFromJson(Map<String, dynamic> json) =>
    DeviceSalePayment(
      method: SalePaymentMethodEnum.fromJson(json['method'] as String),
      amountTiyin: (json['amount_tiyin'] as num).toInt(),
      receivedTiyin: (json['received_tiyin'] as num?)?.toInt(),
      changeTiyin: (json['change_tiyin'] as num).toInt(),
    );

Map<String, dynamic> _$DeviceSalePaymentToJson(DeviceSalePayment instance) =>
    <String, dynamic>{
      'method': _$SalePaymentMethodEnumEnumMap[instance.method]!,
      'amount_tiyin': instance.amountTiyin,
      'received_tiyin': ?instance.receivedTiyin,
      'change_tiyin': instance.changeTiyin,
    };

const _$SalePaymentMethodEnumEnumMap = {
  SalePaymentMethodEnum.cash: 'cash',
  SalePaymentMethodEnum.card: 'card',
  SalePaymentMethodEnum.debt: 'debt',
  SalePaymentMethodEnum.$unknown: r'$unknown',
};
