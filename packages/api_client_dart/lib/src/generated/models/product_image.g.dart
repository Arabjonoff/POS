// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductImage _$ProductImageFromJson(Map<String, dynamic> json) => ProductImage(
  product: json['product'] as String,
  sha256: json['sha256'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  bytes: (json['bytes'] as num).toInt(),
  id: json['id'] as String?,
);

Map<String, dynamic> _$ProductImageToJson(ProductImage instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'product': instance.product,
      'sha256': instance.sha256,
      'width': instance.width,
      'height': instance.height,
      'bytes': instance.bytes,
    };
