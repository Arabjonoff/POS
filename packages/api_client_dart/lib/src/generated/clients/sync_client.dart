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
import '../models/device_report.dart';
import '../models/device_sale.dart';
import '../models/price_history.dart';
import '../models/product_image.dart';
import '../models/pull_response.dart';
import '../models/push_request_request.dart';
import '../models/push_response.dart';
import '../models/size.dart';
import '../models/stock_movement_entry.dart';
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

  @GET('/api/v1/sync/product-images/{id}/')
  @DioResponseType(ResponseType.stream)
  Stream<String> syncProductImagesRetrieve({
    @Path('id') required String id,
    @Query('size') Size? size,
  });

  @MultiPart()
  @PUT('/api/v1/sync/product-images/{id}/')
  Future<ProductImage> syncProductImagesUpdate({
    @Path('id') required String id,
    @Part(name: 'file') required File file,
    @Part(name: 'product') required String product,
    @Part(name: 'by') required String by,
  });

  @DELETE('/api/v1/sync/product-images/{id}/')
  Future<void> syncProductImagesDestroy({
    @Path('id') required String id,
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

  /// Kassa (qurilma tokeni) uchun barcha hisobotlar bitta javobda (T-070).
  ///
  /// Kim ko'rishi (ega/menejer) — kassada lokal rol bilan cheklanadi.
  ///
  /// [dateFrom] - Do'kon vaqt zonasida.
  ///
  /// [dateTo] - Shu kun ham kiradi; ≤ 366 kun.
  @GET('/api/v1/sync/reports/')
  Future<DeviceReport> syncReportsRetrieve({
    @Query('date_from') DateTime? dateFrom,
    @Query('date_to') DateTime? dateTo,
  });

  /// Boshqa kassa cheki chek raqami bo'yicha (onlayn, T-110, Q-006 → A):.
  /// ko'rish, qayta chop etish, qaytarish uchun. Qurilma tokeni, faqat o'z.
  /// tenanti; qatorlarda — oldin qaytarilgan miqdor va summa.
  @GET('/api/v1/sync/sales/')
  Future<DeviceSale> syncSaleByNumber({
    @Query('number') required String number,
  });

  /// Kassa uchun tovar qoldiq harakatlari (onlayn, T-054): barcha kassalar,.
  /// oxirgi 100 ta, faqat o'z tenanti.
  @GET('/api/v1/sync/stock-movements/')
  Future<List<StockMovementEntry>> syncStockMovementsList({
    @Query('product') required String product,
  });
}
