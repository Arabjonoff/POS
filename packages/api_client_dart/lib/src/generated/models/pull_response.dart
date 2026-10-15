// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_release.dart';
import 'change.dart';
import 'subscription_snapshot.dart';

part 'pull_response.g.dart';

@JsonSerializable()
class PullResponse {
  const PullResponse({
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
    required this.subscription,
    required this.serverTime,
    this.app,
    this.features,
  });
  
  factory PullResponse.fromJson(Map<String, Object?> json) => _$PullResponseFromJson(json);
  
  final List<Change> changes;
  @JsonKey(name: 'next_cursor')
  final String nextCursor;
  @JsonKey(name: 'has_more')
  final bool hasMore;
  final SubscriptionSnapshot subscription;
  final AppRelease? app;
  final List<String>? features;
  @JsonKey(name: 'server_time')
  final DateTime serverTime;

  Map<String, Object?> toJson() => _$PullResponseToJson(this);
}
