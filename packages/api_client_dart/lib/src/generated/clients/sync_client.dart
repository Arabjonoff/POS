// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/apply_request_request.dart';
import '../models/apply_response.dart';
import '../models/check_request_request.dart';
import '../models/check_response.dart';
import '../models/price_history.dart';
import '../models/pull_response.dart';
import '../models/push_request_request.dart';
import '../models/push_response.dart';
import '../models/upload_response.dart';

part 'sync_client.g.dart';

@RestApi()
abstract class SyncClient {
  factory SyncClient(Dio dio, {String? baseUrl}) = _SyncClient;

  /// Kassa uchun tovar narx tarixi (onlayn): qurilma tokeni bilan, faqat.
  /// o'z tenanti. Kim ko'rishi (menejer/ega) — kassada lokal PIN bilan.
  @GET('/api/v1/sync/price-history/')
  Future<List<PriceHistory>> syncPriceHistoryList({
    @Query('product') required String product,
  });

  @GET('/api/v1/sync/product-import/template/')
  @DioResponseType(ResponseType.stream)
  Stream<String> syncProductImportTemplateRetrieve();

  @MultiPart()
  @POST('/api/v1/sync/product-imports/')
  Future<UploadResponse> syncProductImportsCreate({
    @Part(name: 'file') required File file,
  });

  @POST('/api/v1/sync/product-imports/{id}/apply/')
  Future<ApplyResponse> syncProductImportsApplyCreate({
    @Path('id') required String id,
    @Body() required ApplyRequestRequest body,
  });

  @POST('/api/v1/sync/product-imports/{id}/check/')
  Future<CheckResponse> syncProductImportsCheckCreate({
    @Path('id') required String id,
    @Body() required CheckRequestRequest body,
  });

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
