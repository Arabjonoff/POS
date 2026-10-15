// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'day_row.g.dart';

@JsonSerializable()
class DayRow {
  const DayRow({
    required this.date,
    required this.revenueTiyin,
    required this.salesCount,
    required this.profitTiyin,
  });
  
  factory DayRow.fromJson(Map<String, Object?> json) => _$DayRowFromJson(json);
  
  final DateTime date;
  @JsonKey(name: 'revenue_tiyin')
  final int revenueTiyin;
  @JsonKey(name: 'sales_count')
  final int salesCount;
  @JsonKey(name: 'profit_tiyin')
  final int profitTiyin;

  Map<String, Object?> toJson() => _$DayRowToJson(this);
}
