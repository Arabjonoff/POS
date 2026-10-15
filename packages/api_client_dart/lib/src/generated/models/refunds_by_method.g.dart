// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refunds_by_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundsByMethod _$RefundsByMethodFromJson(Map<String, dynamic> json) =>
    RefundsByMethod(
      cash: (json['cash'] as num).toInt(),
      debt: (json['debt'] as num).toInt(),
    );

Map<String, dynamic> _$RefundsByMethodToJson(RefundsByMethod instance) =>
    <String, dynamic>{'cash': instance.cash, 'debt': instance.debt};
