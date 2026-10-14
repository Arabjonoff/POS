// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_request_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplyRequestRequest _$ApplyRequestRequestFromJson(Map<String, dynamic> json) =>
    ApplyRequestRequest(
      mapping: MappingRequest.fromJson(json['mapping'] as Map<String, dynamic>),
      by: json['by'] as String,
    );

Map<String, dynamic> _$ApplyRequestRequestToJson(
  ApplyRequestRequest instance,
) => <String, dynamic>{'mapping': instance.mapping.toJson(), 'by': instance.by};
