// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Debts _$DebtsFromJson(Map<String, dynamic> json) => Debts(
  totalDebtTiyin: (json['total_debt_tiyin'] as num).toInt(),
  debtorsCount: (json['debtors_count'] as num).toInt(),
  top: (json['top'] as List<dynamic>)
      .map((e) => Debtor.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCreditTiyin: (json['total_credit_tiyin'] as num?)?.toInt(),
  creditorsCount: (json['creditors_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$DebtsToJson(Debts instance) => <String, dynamic>{
  'total_debt_tiyin': instance.totalDebtTiyin,
  'debtors_count': instance.debtorsCount,
  'total_credit_tiyin': ?instance.totalCreditTiyin,
  'creditors_count': ?instance.creditorsCount,
  'top': instance.top.map((e) => e.toJson()).toList(),
};
