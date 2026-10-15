// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'debtor.g.dart';

@JsonSerializable()
class Debtor {
  const Debtor({
    required this.customer,
    required this.fullName,
    required this.phone,
    required this.balanceTiyin,
  });
  
  factory Debtor.fromJson(Map<String, Object?> json) => _$DebtorFromJson(json);
  
  final String customer;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String phone;
  @JsonKey(name: 'balance_tiyin')
  final int balanceTiyin;

  Map<String, Object?> toJson() => _$DebtorToJson(this);
}
