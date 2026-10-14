// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_device_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedDeviceList _$PaginatedDeviceListFromJson(Map<String, dynamic> json) =>
    PaginatedDeviceList(
      count: (json['count'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => Device.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );

Map<String, dynamic> _$PaginatedDeviceListToJson(
  PaginatedDeviceList instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': ?instance.next,
  'previous': ?instance.previous,
  'results': instance.results.map((e) => e.toJson()).toList(),
};
