// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadResponse _$UploadResponseFromJson(Map<String, dynamic> json) =>
    UploadResponse(
      id: json['id'] as String,
      columns: (json['columns'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sample: (json['sample'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as String).toList())
          .toList(),
      totalRows: (json['total_rows'] as num).toInt(),
      mapping: Mapping.fromJson(json['mapping'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UploadResponseToJson(UploadResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'columns': instance.columns,
      'sample': instance.sample,
      'total_rows': instance.totalRows,
      'mapping': instance.mapping.toJson(),
    };
