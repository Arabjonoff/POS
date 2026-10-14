// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'mapping.g.dart';

@JsonSerializable()
class Mapping {
  const Mapping({
    this.name,
    this.barcode,
    this.category,
    this.unit,
    this.sellPrice,
    this.costPrice,
    this.stock,
  });
  
  factory Mapping.fromJson(Map<String, Object?> json) => _$MappingFromJson(json);
  
  final int? name;
  final int? barcode;
  final int? category;
  final int? unit;
  @JsonKey(name: 'sell_price')
  final int? sellPrice;
  @JsonKey(name: 'cost_price')
  final int? costPrice;
  final int? stock;

  Map<String, Object?> toJson() => _$MappingToJson(this);
}
