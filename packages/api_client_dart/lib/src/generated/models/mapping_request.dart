// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'mapping_request.g.dart';

@JsonSerializable()
class MappingRequest {
  const MappingRequest({
    this.name,
    this.barcode,
    this.category,
    this.unit,
    this.sellPrice,
    this.costPrice,
    this.stock,
  });
  
  factory MappingRequest.fromJson(Map<String, Object?> json) => _$MappingRequestFromJson(json);
  
  final int? name;
  final int? barcode;
  final int? category;
  final int? unit;
  @JsonKey(name: 'sell_price')
  final int? sellPrice;
  @JsonKey(name: 'cost_price')
  final int? costPrice;
  final int? stock;

  Map<String, Object?> toJson() => _$MappingRequestToJson(this);
}
