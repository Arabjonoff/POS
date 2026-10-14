// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplyResponse _$ApplyResponseFromJson(Map<String, dynamic> json) =>
    ApplyResponse(
      created: (json['created'] as num).toInt(),
      updated: (json['updated'] as num).toInt(),
      skipped: (json['skipped'] as num).toInt(),
      errorCount: (json['error_count'] as num).toInt(),
      errors: (json['errors'] as List<dynamic>)
          .map((e) => RowError.fromJson(e as Map<String, dynamic>))
          .toList(),
      receipt: (json['receipt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ApplyResponseToJson(ApplyResponse instance) =>
    <String, dynamic>{
      'created': instance.created,
      'updated': instance.updated,
      'skipped': instance.skipped,
      'error_count': instance.errorCount,
      'errors': instance.errors.map((e) => e.toJson()).toList(),
      'receipt': ?instance.receipt,
    };
