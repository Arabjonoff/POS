// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'hour_row.g.dart';

@JsonSerializable()
class HourRow {
  const HourRow({
    required this.hour,
    required this.revenueTiyin,
    required this.salesCount,
  });
  
  factory HourRow.fromJson(Map<String, Object?> json) => _$HourRowFromJson(json);
  
  final int hour;
  @JsonKey(name: 'revenue_tiyin')
  final int revenueTiyin;
  @JsonKey(name: 'sales_count')
  final int salesCount;

  Map<String, Object?> toJson() => _$HourRowToJson(this);
}
