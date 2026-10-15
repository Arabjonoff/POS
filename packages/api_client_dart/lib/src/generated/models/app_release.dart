// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_release.g.dart';

/// Kassa ilovasining oxirgi versiyasi (T-093).
@JsonSerializable()
class AppRelease {
  const AppRelease({
    required this.latestVersion,
    required this.downloadUrl,
  });
  
  factory AppRelease.fromJson(Map<String, Object?> json) => _$AppReleaseFromJson(json);
  
  @JsonKey(name: 'latest_version')
  final String latestVersion;
  @JsonKey(name: 'download_url')
  final String downloadUrl;

  Map<String, Object?> toJson() => _$AppReleaseToJson(this);
}
