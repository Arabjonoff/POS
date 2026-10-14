// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/pull_response.dart';
import '../models/push_request_request.dart';
import '../models/push_response.dart';

part 'sync_client.g.dart';

@RestApi()
abstract class SyncClient {
  factory SyncClient(Dio dio, {String? baseUrl}) = _SyncClient;

  /// Server o'zgarishlari (ChangeLog) kursor bo'yicha + obuna holati.
  @GET('/api/v1/sync/pull/')
  Future<PullResponse> syncPullRetrieve({
    @Query('cursor') String? cursor = '0',
    @Query('limit') int? limit = 500,
  });

  /// Kassa hodisalarini qabul qiladi (idempotent, paketli).
  @POST('/api/v1/sync/push/')
  Future<PushResponse> syncPushCreate({
    @Body() required PushRequestRequest body,
  });
}
