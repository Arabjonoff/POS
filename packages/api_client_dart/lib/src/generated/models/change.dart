// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'op_enum.dart';

part 'change.g.dart';

@JsonSerializable()
class Change {
  const Change({
    required this.entity,
    required this.op,
    required this.id,
    required this.data,
  });
  
  factory Change.fromJson(Map<String, Object?> json) => _$ChangeFromJson(json);
  
  final String entity;
  final OpEnum op;
  final String id;
  final dynamic data;

  Map<String, Object?> toJson() => _$ChangeToJson(this);
}
