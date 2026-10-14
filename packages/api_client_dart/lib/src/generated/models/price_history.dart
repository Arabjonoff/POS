// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'price_history.g.dart';

/// Narx o'zgarishi (faqat o'qish): kim va qachon.
@JsonSerializable()
class PriceHistory {
  const PriceHistory({
    required this.id,
    required this.sellPriceTiyin,
    required this.costPriceTiyin,
    required this.changedBy,
    required this.changedByName,
    required this.at,
  });
  
  factory PriceHistory.fromJson(Map<String, Object?> json) => _$PriceHistoryFromJson(json);
  
  final String id;
  @JsonKey(name: 'sell_price_tiyin')
  final int sellPriceTiyin;
  @JsonKey(name: 'cost_price_tiyin')
  final int costPriceTiyin;
  @JsonKey(name: 'changed_by')
  final String? changedBy;
  @JsonKey(name: 'changed_by_name')
  final String? changedByName;
  final DateTime at;

  Map<String, Object?> toJson() => _$PriceHistoryToJson(this);
}
