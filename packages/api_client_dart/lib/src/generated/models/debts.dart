// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'debtor.dart';

part 'debts.g.dart';

@JsonSerializable()
class Debts {
  const Debts({
    required this.totalDebtTiyin,
    required this.debtorsCount,
    required this.top,
    this.totalCreditTiyin,
    this.creditorsCount,
  });
  
  factory Debts.fromJson(Map<String, Object?> json) => _$DebtsFromJson(json);
  
  @JsonKey(name: 'total_debt_tiyin')
  final int totalDebtTiyin;
  @JsonKey(name: 'debtors_count')
  final int debtorsCount;
  @JsonKey(name: 'total_credit_tiyin')
  final int? totalCreditTiyin;
  @JsonKey(name: 'creditors_count')
  final int? creditorsCount;
  final List<Debtor> top;

  Map<String, Object?> toJson() => _$DebtsToJson(this);
}
