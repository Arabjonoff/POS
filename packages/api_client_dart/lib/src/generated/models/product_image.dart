// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_image.g.dart';

@JsonSerializable()
class ProductImage {
  const ProductImage({
    required this.product,
    required this.sha256,
    required this.width,
    required this.height,
    required this.bytes,
    this.id,
  });
  
  factory ProductImage.fromJson(Map<String, Object?> json) => _$ProductImageFromJson(json);
  
  final String? id;
  final String product;
  final String sha256;
  final int width;
  final int height;
  final int bytes;

  Map<String, Object?> toJson() => _$ProductImageToJson(this);
}
