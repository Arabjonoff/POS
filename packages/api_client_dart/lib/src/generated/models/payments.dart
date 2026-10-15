// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'payments.g.dart';

@JsonSerializable()
class Payments {
  const Payments({
    required this.cash,
    required this.card,
    required this.debt,
  });
  
  factory Payments.fromJson(Map<String, Object?> json) => _$PaymentsFromJson(json);
  
  final int cash;
  final int card;
  final int debt;

  Map<String, Object?> toJson() => _$PaymentsToJson(this);
}
