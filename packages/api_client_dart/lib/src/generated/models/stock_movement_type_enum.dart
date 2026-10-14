// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `receipt` - kirim.
/// * `sale` - savdo.
/// * `refund` - qaytarish.
/// * `adjustment` - tuzatish.
/// * `inventory` - inventarizatsiya.
@JsonEnum()
enum StockMovementTypeEnum {
  @JsonValue('receipt')
  receipt('receipt'),
  @JsonValue('sale')
  sale('sale'),
  @JsonValue('refund')
  refund('refund'),
  @JsonValue('adjustment')
  adjustment('adjustment'),
  @JsonValue('inventory')
  inventory('inventory'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const StockMovementTypeEnum(this.json);

  factory StockMovementTypeEnum.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<StockMovementTypeEnum> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
