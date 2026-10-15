// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'device_sale_item.g.dart';

@JsonSerializable()
class DeviceSaleItem {
  const DeviceSaleItem({
    required this.id,
    required this.product,
    required this.nameSnapshot,
    required this.barcodeSnapshot,
    required this.qtyMilli,
    required this.priceTiyin,
    required this.discountTiyin,
    required this.totalTiyin,
    required this.refundedQtyMilli,
    required this.refundedTiyin,
  });
  
  factory DeviceSaleItem.fromJson(Map<String, Object?> json) => _$DeviceSaleItemFromJson(json);
  
  final String id;
  final String product;
  @JsonKey(name: 'name_snapshot')
  final String nameSnapshot;
  @JsonKey(name: 'barcode_snapshot')
  final String barcodeSnapshot;
  @JsonKey(name: 'qty_milli')
  final int qtyMilli;
  @JsonKey(name: 'price_tiyin')
  final int priceTiyin;
  @JsonKey(name: 'discount_tiyin')
  final int discountTiyin;
  @JsonKey(name: 'total_tiyin')
  final int totalTiyin;
  @JsonKey(name: 'refunded_qty_milli')
  final int refundedQtyMilli;
  @JsonKey(name: 'refunded_tiyin')
  final int refundedTiyin;

  Map<String, Object?> toJson() => _$DeviceSaleItemToJson(this);
}
