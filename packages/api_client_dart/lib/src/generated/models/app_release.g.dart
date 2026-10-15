// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppRelease _$AppReleaseFromJson(Map<String, dynamic> json) => AppRelease(
  latestVersion: json['latest_version'] as String,
  downloadUrl: json['download_url'] as String,
);

Map<String, dynamic> _$AppReleaseToJson(AppRelease instance) =>
    <String, dynamic>{
      'latest_version': instance.latestVersion,
      'download_url': instance.downloadUrl,
    };
