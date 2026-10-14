// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'subscription_snapshot.g.dart';

@JsonSerializable()
class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.status,
    required this.paidUntil,
    required this.daysLeft,
    required this.offlineDays,
  });
  
  factory SubscriptionSnapshot.fromJson(Map<String, Object?> json) => _$SubscriptionSnapshotFromJson(json);
  
  final String status;
  @JsonKey(name: 'paid_until')
  final DateTime? paidUntil;
  @JsonKey(name: 'days_left')
  final int? daysLeft;
  @JsonKey(name: 'offline_days')
  final int offlineDays;

  Map<String, Object?> toJson() => _$SubscriptionSnapshotToJson(this);
}
