// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `platform_admin` - platforma admini.
/// * `owner` - ega.
/// * `manager` - menejer.
/// * `cashier` - kassir.
@JsonEnum()
enum RoleEnum {
  @JsonValue('platform_admin')
  platformAdmin('platform_admin'),
  @JsonValue('owner')
  owner('owner'),
  @JsonValue('manager')
  manager('manager'),
  @JsonValue('cashier')
  cashier('cashier'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const RoleEnum(this.json);

  factory RoleEnum.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<RoleEnum> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
