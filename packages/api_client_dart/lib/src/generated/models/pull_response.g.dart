// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pull_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PullResponse _$PullResponseFromJson(Map<String, dynamic> json) => PullResponse(
  changes: (json['changes'] as List<dynamic>)
      .map((e) => Change.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['next_cursor'] as String,
  hasMore: json['has_more'] as bool,
  subscription: SubscriptionSnapshot.fromJson(
    json['subscription'] as Map<String, dynamic>,
  ),
  serverTime: DateTime.parse(json['server_time'] as String),
  app: json['app'] == null
      ? null
      : AppRelease.fromJson(json['app'] as Map<String, dynamic>),
  features: (json['features'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$PullResponseToJson(PullResponse instance) =>
    <String, dynamic>{
      'changes': instance.changes.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
      'has_more': instance.hasMore,
      'subscription': instance.subscription.toJson(),
      'app': ?instance.app?.toJson(),
      'features': ?instance.features,
      'server_time': instance.serverTime.toIso8601String(),
    };
