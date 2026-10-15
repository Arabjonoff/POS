// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'previous.g.dart';

@JsonSerializable()
class Previous {
  const Previous({
    required this.revenueTiyin,
    required this.profitTiyin,
    required this.salesCount,
  });
  
  factory Previous.fromJson(Map<String, Object?> json) => _$PreviousFromJson(json);
  
  @JsonKey(name: 'revenue_tiyin')
  final int revenueTiyin;
  @JsonKey(name: 'profit_tiyin')
  final int profitTiyin;
  @JsonKey(name: 'sales_count')
  final int salesCount;

  Map<String, Object?> toJson() => _$PreviousToJson(this);
}
