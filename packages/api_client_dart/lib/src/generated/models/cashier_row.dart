// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cashier_row.g.dart';

@JsonSerializable()
class CashierRow {
  const CashierRow({
    required this.cashier,
    required this.fullName,
    required this.salesCount,
    required this.salesTotalTiyin,
    required this.refundsCount,
    required this.refundsTotalTiyin,
  });
  
  factory CashierRow.fromJson(Map<String, Object?> json) => _$CashierRowFromJson(json);
  
  final String cashier;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'sales_count')
  final int salesCount;
  @JsonKey(name: 'sales_total_tiyin')
  final int salesTotalTiyin;
  @JsonKey(name: 'refunds_count')
  final int refundsCount;
  @JsonKey(name: 'refunds_total_tiyin')
  final int refundsTotalTiyin;

  Map<String, Object?> toJson() => _$CashierRowToJson(this);
}
