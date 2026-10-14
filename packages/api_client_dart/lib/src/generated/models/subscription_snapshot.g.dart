// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionSnapshot _$SubscriptionSnapshotFromJson(
  Map<String, dynamic> json,
) => SubscriptionSnapshot(
  status: json['status'] as String,
  paidUntil: json['paid_until'] == null
      ? null
      : DateTime.parse(json['paid_until'] as String),
  daysLeft: (json['days_left'] as num?)?.toInt(),
  offlineDays: (json['offline_days'] as num).toInt(),
);

Map<String, dynamic> _$SubscriptionSnapshotToJson(
  SubscriptionSnapshot instance,
) => <String, dynamic>{
  'status': instance.status,
  'paid_until': ?instance.paidUntil?.toIso8601String(),
  'days_left': ?instance.daysLeft,
  'offline_days': instance.offlineDays,
};
