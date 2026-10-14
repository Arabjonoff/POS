// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckResponse _$CheckResponseFromJson(Map<String, dynamic> json) =>
    CheckResponse(
      creates: (json['creates'] as num).toInt(),
      updates: (json['updates'] as num).toInt(),
      errorCount: (json['error_count'] as num).toInt(),
      errors: (json['errors'] as List<dynamic>)
          .map((e) => RowError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CheckResponseToJson(CheckResponse instance) =>
    <String, dynamic>{
      'creates': instance.creates,
      'updates': instance.updates,
      'error_count': instance.errorCount,
      'errors': instance.errors.map((e) => e.toJson()).toList(),
    };
