// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payments _$PaymentsFromJson(Map<String, dynamic> json) => Payments(
  cash: (json['cash'] as num).toInt(),
  card: (json['card'] as num).toInt(),
  debt: (json['debt'] as num).toInt(),
);

Map<String, dynamic> _$PaymentsToJson(Payments instance) => <String, dynamic>{
  'cash': instance.cash,
  'card': instance.card,
  'debt': instance.debt,
};
