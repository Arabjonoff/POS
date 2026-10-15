// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'refunds_by_method.g.dart';

@JsonSerializable()
class RefundsByMethod {
  const RefundsByMethod({
    required this.cash,
    required this.debt,
  });
  
  factory RefundsByMethod.fromJson(Map<String, Object?> json) => _$RefundsByMethodFromJson(json);
  
  final int cash;
  final int debt;

  Map<String, Object?> toJson() => _$RefundsByMethodToJson(this);
}
