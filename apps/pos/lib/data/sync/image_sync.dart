import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:pos_app/data/catalog/product_images.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Tovar rasmlari sinxroni (T-105): JSON outbox'dan alohida. Asosiy sinxron
/// (push → pull) bunga bog'liq emas — bu yerdagi xato savdo, kirim va boshqa
/// hodisalarni hech qachon to'xtatmaydi.
///
/// - [upload]: `local` rasmlar → `PUT /sync/product-images/{id}/` (2 tadan).
///   `409 product_missing` — tovar hodisasi hali qo'llanmagan, keyinroq;
///   `400` — rasm qabul qilinmadi (`failed`, qayta urinilmaydi).
/// - [deleteRemoved]: `delete` holatidagilar → `DELETE`.
/// - [download]: rasmi bor, lekin fayli yo'q tovarlar → `GET` (oflaynda
///   placeholder ko'rinadi, ekran tarmoqni kutmaydi).
class ProductImageSync {
  ProductImageSync(
    this._db,
    this._images,
    this._dio, {
    DateTime Function()? now,
  }) : _now = now ?? _clockNow;

  static DateTime _clockNow() => clock.now();

  static const Duration minBackoff = Duration(seconds: 30);
  static const Duration maxBackoff = Duration(minutes: 30);
  static const int batch = 2;

  final AppDatabase _db;
  final ProductImageStore _images;

  /// Qurilma tokeni bilan Dio; token yo'q — `null`.
  final Future<Dio?> Function() _dio;
  final DateTime Function() _now;

  static String _path(String id) => '/api/v1/sync/product-images/$id/';

  Duration _backoff(int attempts) => Duration(
    milliseconds: math
        .min(
          minBackoff.inMilliseconds * math.pow(2, math.max(0, attempts - 1)),
          maxBackoff.inMilliseconds,
        )
        .toInt(),
  );

  Future<List<ProductImage>> _due(String state) async {
    final now = _now();
    return (_db.select(_db.productImages)
          ..where(
            (i) =>
                i.state.equals(state) &
                (i.nextAttemptAt.isNull() |
                    i.nextAttemptAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(i) => OrderingTerm.asc(i.createdAt)])
          ..limit(batch))
        .get();
  }

  Future<void> _postpone(ProductImage row, String error) =>
      (_db.update(
        _db.productImages,
      )..where((i) => i.id.equals(row.id))).write(
        ProductImagesCompanion(
          attempts: Value(row.attempts + 1),
          nextAttemptAt: Value(_now().add(_backoff(row.attempts + 1))),
          lastError: Value(error),
        ),
      );

  Future<void> _setState(String id, String state, {String? error}) =>
      (_db.update(_db.productImages)..where((i) => i.id.equals(id))).write(
        ProductImagesCompanion(
          state: Value(state),
          attempts: const Value(0),
          nextAttemptAt: const Value(null),
          lastError: Value(error),
        ),
      );

  /// Hammasi: yuklash, o'chirish, yuklab olish. Tarmoq yo'q — jim to'xtaydi.
  Future<void> run() async {
    final dio = await _dio();
    if (dio == null) return;
    try {
      await upload(dio);
      await deleteRemoved(dio);
      await download(dio);
    } on DioException {
      // Tarmoq: keyingi siklda.
    }
  }

  Future<void> upload(Dio dio) async {
    for (final row in await _due(ImageState.local)) {
      final file = await _images.existing(row.id);
      if (file == null) {
        await _setState(row.id, ImageState.failed, error: 'file_missing');
        continue;
      }
      try {
        await dio.put<Object?>(
          _path(row.id),
          data: FormData.fromMap({
            // Baytlar xotirada (~100 KB): fayl oqimi tarmoq xatosida ochiq
            // qolib, Windows'da faylni band qilmasin.
            'file': MultipartFile.fromBytes(
              file.readAsBytesSync(),
              filename: '${row.id}.jpg',
              contentType: DioMediaType('image', 'jpeg'),
            ),
            'product': row.productId,
            'by': row.byUserId,
          }),
          options: Options(contentType: 'multipart/form-data'),
        );
        await _setState(row.id, ImageState.uploaded);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == null || status >= 500 || status == 409) {
          await _postpone(row, '${status ?? 'network'}');
          if (status == null) rethrow;
        } else {
          await _setState(row.id, ImageState.failed, error: '$status');
        }
      }
    }
  }

  Future<void> deleteRemoved(Dio dio) async {
    for (final row in await _due(ImageState.delete)) {
      try {
        await dio.delete<Object?>(
          _path(row.id),
          data: {'by': row.byUserId},
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == null || status >= 500) {
          await _postpone(row, '${status ?? 'network'}');
          if (status == null) rethrow;
          continue;
        }
      }
      await (_db.delete(
        _db.productImages,
      )..where((i) => i.id.equals(row.id))).go();
      final file = await _images.fileFor(row.id);
      if (file.existsSync()) file.deleteSync();
    }
  }

  /// Rasmi bor, lekin fayli yo'q tovarlar (boshqa kassada qo'yilgan).
  Future<int> download(Dio dio, {int limit = 20}) async {
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.imageId.isNotNull() & p.deletedAt.isNull())).get();
    var fetched = 0;
    for (final p in products) {
      if (fetched >= limit) break;
      final id = p.imageId!;
      if (await _images.existing(id) != null) continue;
      final row = await (_db.select(
        _db.productImages,
      )..where((i) => i.id.equals(id))).getSingleOrNull();
      if (row != null &&
          row.nextAttemptAt != null &&
          row.nextAttemptAt!.isAfter(_now())) {
        continue;
      }
      try {
        final response = await dio.get<List<int>>(
          _path(id),
          options: Options(responseType: ResponseType.bytes),
        );
        await _images.writeFile(id, Uint8List.fromList(response.data!));
        await _db
            .into(_db.productImages)
            .insertOnConflictUpdate(
              ProductImagesCompanion.insert(
                id: id,
                productId: p.id,
                state: ImageState.remote,
                createdAt: _now(),
              ),
            );
        fetched++;
      } on DioException catch (e) {
        if (e.response == null) rethrow;
        // 404 (o'chirilgan) yoki server xatosi — keyinroq qayta urinish.
        final failed =
            row ??
            ProductImage(
              id: id,
              productId: p.id,
              state: ImageState.remote,
              attempts: 0,
              createdAt: _now(),
            );
        if (row == null) {
          await _db.into(_db.productImages).insert(failed);
        }
        await _postpone(failed, '${e.response!.statusCode}');
      }
    }
    return fetched;
  }
}
