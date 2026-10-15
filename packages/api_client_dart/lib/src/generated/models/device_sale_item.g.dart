// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_sale_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceSaleItem _$DeviceSaleItemFromJson(Map<String, dynamic> json) =>
    DeviceSaleItem(
      id: json['id'] as String,
      product: json['product'] as String,
      nameSnapshot: json['name_snapshot'] as String,
      barcodeSnapshot: json['barcode_snapshot'] as String,
      qtyMilli: (json['qty_milli'] as num).toInt(),
      priceTiyin: (json['price_tiyin'] as num).toInt(),
      discountTiyin: (json['discount_tiyin'] as num).toInt(),
      totalTiyin: (json['total_tiyin'] as num).toInt(),
      refundedQtyMilli: (json['refunded_qty_milli'] as num).toInt(),
      refundedTiyin: (json['refunded_tiyin'] as num).toInt(),
    );

Map<String, dynamic> _$DeviceSaleItemToJson(DeviceSaleItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product': instance.product,
      'name_snapshot': instance.nameSnapshot,
      'barcode_snapshot': instance.barcodeSnapshot,
      'qty_milli': instance.qtyMilli,
      'price_tiyin': instance.priceTiyin,
      'discount_tiyin': instance.discountTiyin,
      'total_tiyin': instance.totalTiyin,
      'refunded_qty_milli': instance.refundedQtyMilli,
      'refunded_tiyin': instance.refundedTiyin,
    };
