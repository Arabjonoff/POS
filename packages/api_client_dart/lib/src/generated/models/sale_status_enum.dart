// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `completed` - yakunlangan.
/// * `partially_refunded` - qisman qaytarilgan.
/// * `refunded` - qaytarilgan.
@JsonEnum()
enum SaleStatusEnum {
  @JsonValue('completed')
  completed('completed'),
  @JsonValue('partially_refunded')
  partiallyRefunded('partially_refunded'),
  @JsonValue('refunded')
  refunded('refunded'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const SaleStatusEnum(this.json);

  factory SaleStatusEnum.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<SaleStatusEnum> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
