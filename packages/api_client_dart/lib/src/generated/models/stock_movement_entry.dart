// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stock_movement_type_enum.dart';

part 'stock_movement_entry.g.dart';

@JsonSerializable()
class StockMovementEntry {
  const StockMovementEntry({
    required this.id,
    required this.type,
    required this.qtyMilli,
    required this.refType,
    required this.at,
    required this.createdByName,
  });
  
  factory StockMovementEntry.fromJson(Map<String, Object?> json) => _$StockMovementEntryFromJson(json);
  
  final String id;
  final StockMovementTypeEnum type;
  @JsonKey(name: 'qty_milli')
  final int qtyMilli;
  @JsonKey(name: 'ref_type')
  final String refType;
  final DateTime at;
  @JsonKey(name: 'created_by_name')
  final String? createdByName;

  Map<String, Object?> toJson() => _$StockMovementEntryToJson(this);
}
