// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/device.dart';
import '../models/device_me.dart';
import '../models/device_register_request.dart';
import '../models/device_register_response.dart';
import '../models/paginated_device_list.dart';

part 'devices_client.g.dart';

@RestApi()
abstract class DevicesClient {
  factory DevicesClient(Dio dio, {String? baseUrl}) = _DevicesClient;

  /// O'z tenanti qurilmalari (ega va menejer).
  ///
  /// [page] - A page number within the paginated result set.
  ///
  /// [pageSize] - Number of results to return per page.
  @GET('/api/v1/devices/')
  Future<PaginatedDeviceList> devicesList({
    @Query('page') int? page,
    @Query('page_size') int? pageSize,
  });

  /// O'z tenanti qurilmalari (ega va menejer).
  ///
  /// [id] - A UUID string identifying this qurilma.
  @GET('/api/v1/devices/{id}/')
  Future<Device> devicesRetrieve({
    @Path('id') required String id,
  });

  /// Qurilma o'zi haqida va obuna holati (kassa ulanganda tekshiradi).
  @GET('/api/v1/devices/me/')
  Future<DeviceMe> devicesMeRetrieve();

  /// Ega kassa qurilmasini ulaydi; javobda qurilma tokeni (faqat bir marta).
  @POST('/api/v1/devices/register/')
  Future<DeviceRegisterResponse> devicesRegisterCreate({
    @Body() required DeviceRegisterRequest body,
  });
}
