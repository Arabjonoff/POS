import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pos_api_client/pos_api_client.dart' show PullResponse;
import 'package:pos_app/data/catalog/product_images.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/image_sync.dart';
import 'package:pos_app/data/sync/pull.dart';

import '../helpers/catalog_seed.dart';
import '../helpers/sqlite.dart';

Uint8List pngBytes(int width, int height, {bool alpha = false}) =>
    img.encodePng(
      img.Image(width: width, height: height, numChannels: alpha ? 4 : 3)
        ..clear(img.ColorRgba8(200, 30, 30, alpha ? 0 : 255)),
    );

/// Soxta server: PUT/DELETE/GET rasm, javob kodi testda beriladi.
class FakeImageServer implements HttpClientAdapter {
  final List<String> calls = [];
  int putStatus = 201;
  int getStatus = 200;
  bool offline = false;
  Uint8List body = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 4, height: 4)),
  );

  Dio get dio =>
      Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    calls.add('${options.method} ${options.uri.path}');
    if (requestStream != null) await requestStream.drain<void>();
    return switch (options.method) {
      'PUT' => ResponseBody.fromString(
        jsonEncode({'id': 'x'}),
        putStatus,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
      'GET' => ResponseBody.fromBytes(body, getStatus),
      _ => ResponseBody.fromString('', 204),
    };
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late ProductImageStore store;
  late FakeImageServer server;
  late ProductImageSync sync;
  var now = DateTime.utc(2026, 10, 15, 9);
  var ids = 0;

  setUp(() async {
    db = openTestDatabase();
    await seedCatalog(db);
    dir = Directory.systemTemp.createTempSync('pos_img_test_');
    ids = 0;
    now = DateTime.utc(2026, 10, 15, 9);
    store = ProductImageStore(
      db,
      () async => dir,
      newId: () => 'img-${++ids}',
      now: () => now,
    );
    server = FakeImageServer();
    sync = ProductImageSync(db, store, () async => server.dio, now: () => now);
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<Product> product(String id) =>
      (db.select(db.products)..where((p) => p.id.equals(id))).getSingle();
  Future<ProductImage?> row(String id) => (db.select(
    db.productImages,
  )..where((i) => i.id.equals(id))).getSingleOrNull();

  test(
    'prepare: any image → JPEG, longest side ≤ 800, alpha on white',
    () async {
      final jpeg = await prepareProductImage(pngBytes(2000, 1000, alpha: true));
      final decoded = img.decodeJpg(jpeg)!;
      expect((decoded.width, decoded.height), (800, 400));
      // Shaffof joy oq bo'ladi (qora emas).
      expect(decoded.getPixel(10, 10).r, greaterThan(240));
      await expectLater(
        prepareProductImage(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<ProductImageException>()),
      );
    },
  );

  test('set: file, products.image_id and queue row together', () async {
    final id = await store.setImage('p-non', Uint8List(10), by: 'manager-1');
    expect((await product('p-non')).imageId, id);
    expect((await row(id))!.state, ImageState.local);
    expect((await store.existing(id))!.lengthSync(), 10);
    expect(await store.productsWithPendingImages(), {'p-non'});
  });

  test('replace a not-yet-uploaded image: the old one is dropped', () async {
    final first = await store.setImage('p-non', Uint8List(3), by: 'm');
    final second = await store.setImage('p-non', Uint8List(4), by: 'm');
    expect(await row(first), isNull);
    expect(await store.existing(first), isNull);
    expect((await product('p-non')).imageId, second);
  });

  test('upload → uploaded; 409 waits; 400 fails; offline keeps it', () async {
    final id = await store.setImage('p-non', Uint8List(10), by: 'manager-1');
    server.putStatus = 409;
    await sync.run();
    var r = (await row(id))!;
    expect((r.state, r.attempts), (ImageState.local, 1));
    // Kutish vaqti kelmaguncha qayta yuborilmaydi.
    server.calls.clear();
    await sync.run();
    expect(server.calls.where((c) => c.startsWith('PUT')), isEmpty);

    now = now.add(const Duration(minutes: 5));
    server.putStatus = 201;
    await sync.run();
    expect((await row(id))!.state, ImageState.uploaded);

    final bad = await store.setImage('p-cola', Uint8List(10), by: 'm');
    server.putStatus = 400;
    await sync.run();
    r = (await row(bad))!;
    expect(r.state, ImageState.failed);

    final later = await store.setImage('p-sut', Uint8List(10), by: 'm');
    server.offline = true;
    await sync.run();
    expect((await row(later))!.state, ImageState.local);
  });

  test('remove an uploaded image → server delete, then forgotten', () async {
    final id = await store.setImage('p-non', Uint8List(10), by: 'm');
    await sync.run();
    await store.removeImage('p-non', by: 'manager-1');
    expect((await product('p-non')).imageId, isNull);
    expect((await row(id))!.state, ImageState.delete);
    await sync.run();
    expect(server.calls, contains('DELETE /api/v1/sync/product-images/$id/'));
    expect(await row(id), isNull);
    expect(await store.existing(id), isNull);
  });

  test('download: images set on another kassa are fetched once', () async {
    await (db.update(db.products)..where((p) => p.id.equals('p-cola'))).write(
      const ProductsCompanion(imageId: Value('remote-1')),
    );
    await sync.run();
    expect(await store.existing('remote-1'), isNotNull);
    expect((await row('remote-1'))!.state, ImageState.remote);
    server.calls.clear();
    await sync.run();
    expect(server.calls, isEmpty);
  });

  test('pull keeps a local image that is not uploaded yet', () async {
    final id = await store.setImage('p-non', Uint8List(10), by: 'm');
    final applier = PullApplier(db, now: () => now);
    Future<void> pullProduct(Object? image) => applier.apply(
      PullResponse.fromJson({
        'changes': [
          {
            'entity': 'product',
            'op': 'upsert',
            'id': 'p-non',
            'data': {
              'id': 'p-non',
              'name': 'Non issiq',
              'unit': 'u-pcs',
              'sell_price_tiyin': 400000,
              'image': image,
            },
          },
        ],
        'next_cursor': '1',
        'has_more': false,
        'subscription': {
          'status': 'active',
          'paid_until': '2026-11-30',
          'days_left': 47,
          'offline_days': 7,
        },
        'server_time': '2026-10-15T09:00:00Z',
      }),
    );
    await pullProduct(null);
    expect((await product('p-non')).imageId, id);
    // Yuklangandan keyin server holati amalda.
    await sync.run();
    await pullProduct({
      'id': 'server-2',
      'sha256': 'x',
      'width': 1,
      'height': 1,
    });
    expect((await product('p-non')).imageId, 'server-2');
  });
}
