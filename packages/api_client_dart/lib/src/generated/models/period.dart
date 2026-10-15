// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'period.g.dart';

@JsonSerializable()
class Period {
  const Period({
    required this.dateFrom,
    required this.dateTo,
  });
  
  factory Period.fromJson(Map<String, Object?> json) => _$PeriodFromJson(json);
  
  @JsonKey(name: 'date_from')
  final DateTime dateFrom;
  @JsonKey(name: 'date_to')
  final DateTime dateTo;

  Map<String, Object?> toJson() => _$PeriodToJson(this);
}
