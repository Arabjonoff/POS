// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debtor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Debtor _$DebtorFromJson(Map<String, dynamic> json) => Debtor(
  customer: json['customer'] as String,
  fullName: json['full_name'] as String,
  phone: json['phone'] as String,
  balanceTiyin: (json['balance_tiyin'] as num).toInt(),
);

Map<String, dynamic> _$DebtorToJson(Debtor instance) => <String, dynamic>{
  'customer': instance.customer,
  'full_name': instance.fullName,
  'phone': instance.phone,
  'balance_tiyin': instance.balanceTiyin,
};
