import 'dart:io';
import 'dart:isolate';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, StreamProviderFamily;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';

/// Rasm holati (`product_images.state`).
abstract final class ImageState {
  /// Kassada tanlangan, serverga yuklanishi kerak.
  static const String local = 'local';
  static const String uploaded = 'uploaded';

  /// Serverdan yuklab olingan (boshqa kassada qo'yilgan).
  static const String remote = 'remote';

  /// Olib tashlangan — serverdan ham o'chirilishi kerak.
  static const String delete = 'delete';

  /// Server qabul qilmadi (rasm buzuq) — qayta urinilmaydi.
  static const String failed = 'failed';
}

/// Tanlangan rasm o'qilmadi yoki juda katta.
class ProductImageException implements Exception {
  const ProductImageException(this.reason);

  /// `unsupported` | `too_large`.
  final String reason;
}

/// Eng uzun tomon (server ham 800 px gacha kichraytiradi).
const int productImageSide = 800;

/// Kiruvchi fayl chegarasi (telefon kamerasidagi rasm ~5–10 MB).
const int maxSourceImageBytes = 20 * 1024 * 1024;

/// Har qanday rasm (JPEG, PNG, WebP, BMP...) → JPEG, burilish to'g'rilangan,
/// eng uzun tomoni ≤ 800 px, sifat 80 (~50–150 KB). Alohida isolate'da —
/// kassa ekrani qotmaydi.
Future<Uint8List> prepareProductImage(Uint8List bytes) async {
  if (bytes.length > maxSourceImageBytes) {
    throw const ProductImageException('too_large');
  }
  final result = await Isolate.run(() => _prepare(bytes));
  if (result == null) throw const ProductImageException('unsupported');
  return result;
}

Uint8List? _prepare(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > productImageSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: productImageSide)
        : img.copyResize(image, height: productImageSide);
  }
  // Shaffof joy — oq fon (JPEG da alfa yo'q).
  if (image.hasAlpha) {
    final flat = img.Image(width: image.width, height: image.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(flat, image);
  }
  return img.encodeJpg(image, quality: 80);
}

/// Rasmlar papkasi (ilova ma'lumotlari ichida; testlarda vaqtinchalik).
typedef ImageDirectory = Future<Directory> Function();

Future<Directory> _appImageDirectory() async {
  final base = await getApplicationSupportDirectory();
  return Directory('${base.path}${Platform.pathSeparator}product_images')
    ..createSync(recursive: true);
}

final imageDirectoryProvider = Provider<ImageDirectory>(
  (ref) => _appImageDirectory,
);

/// Tovar rasmlari: lokal fayl + navbat. Rasm darhol ko'rinadi (oflayn ham),
/// serverga keyin — `ProductImageSync`.
class ProductImageStore {
  ProductImageStore(
    this._db,
    this._dir, {
    IdGenerator? newId,
    DateTime Function()? now,
  }) : _newId = newId ?? _defaultId,
       _now = now ?? _clockNow;

  static String _defaultId() => newId();
  static DateTime _clockNow() => clock.now();

  final AppDatabase _db;
  final ImageDirectory _dir;
  final IdGenerator _newId;
  final DateTime Function() _now;

  Future<File> fileFor(String imageId) async =>
      File('${(await _dir()).path}${Platform.pathSeparator}$imageId.jpg');

  /// Fayl bor bo'lsa — o'zi, yo'q bo'lsa (hali yuklab olinmagan) — `null`.
  Future<File?> existing(String? imageId) async {
    if (imageId == null) return null;
    final file = await fileFor(imageId);
    return file.existsSync() ? file : null;
  }

  /// Faylni xavfsiz yozish: vaqtinchalik fayl → nomini o'zgartirish
  /// (elektr o'chsa yarim fayl qolmaydi). Rasm kichik (~100 KB) — sinxron.
  Future<void> writeFile(String imageId, Uint8List bytes) async {
    final file = await fileFor(imageId);
    File('${file.path}.tmp')
      ..writeAsBytesSync(bytes, flush: true)
      ..renameSync(file.path);
  }

  /// Tovarga yangi rasm ([jpeg] — [prepareProductImage] natijasi). Fayl,
  /// `products.image_id` va navbat — bitta tranzaksiyada. Qaytaradi: rasm id.
  Future<String> setImage(
    String productId,
    Uint8List jpeg, {
    required String by,
  }) async {
    final id = _newId();
    await writeFile(id, jpeg);
    await _db.transaction(() async {
      await _forgetPrevious(productId, by: by, keepRemote: true);
      await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(imageId: Value(id)));
      await _db
          .into(_db.productImages)
          .insert(
            ProductImagesCompanion.insert(
              id: id,
              productId: productId,
              state: ImageState.local,
              byUserId: Value(by),
              createdAt: _now(),
            ),
          );
    });
    return id;
  }

  /// Rasmni olib tashlash: tovar rasmsiz; serverdagi rasm ham o'chiriladi.
  Future<void> removeImage(String productId, {required String by}) =>
      _db.transaction(() async {
        await _forgetPrevious(productId, by: by, keepRemote: false);
        await (_db.update(_db.products)..where((p) => p.id.equals(productId)))
            .write(const ProductsCompanion(imageId: Value(null)));
      });

  /// Oldingi rasm: hali yuklanmagan bo'lsa — butunlay o'chadi (serverga
  /// keraksiz yuklanmasin); serverda bo'lsa — almashtirishda server yangi
  /// rasmni joriy qiladi ([keepRemote]), olib tashlashda o'chirish navbati.
  Future<void> _forgetPrevious(
    String productId, {
    required String by,
    required bool keepRemote,
  }) async {
    final product = await (_db.select(
      _db.products,
    )..where((p) => p.id.equals(productId))).getSingleOrNull();
    final old = product?.imageId;
    if (old == null) return;
    final row = await (_db.select(
      _db.productImages,
    )..where((i) => i.id.equals(old))).getSingleOrNull();
    if (row == null || row.state == ImageState.local) {
      await (_db.delete(
        _db.productImages,
      )..where((i) => i.id.equals(old))).go();
      final file = await fileFor(old);
      if (file.existsSync()) file.deleteSync();
      return;
    }
    if (!keepRemote) {
      await (_db.update(
        _db.productImages,
      )..where((i) => i.id.equals(old))).write(
        ProductImagesCompanion(
          state: const Value(ImageState.delete),
          byUserId: Value(by),
          attempts: const Value(0),
          nextAttemptAt: const Value(null),
        ),
      );
    }
  }

  /// Serverga hali yetmagan rasmi bor tovarlar (pull ularni bosmasin).
  Future<Set<String>> productsWithPendingImages() async {
    final rows =
        await (_db.select(_db.productImages)..where(
              (i) => i.state.isIn([ImageState.local, ImageState.delete]),
            ))
            .get();
    return {for (final r in rows) r.productId};
  }
}

final productImageStoreProvider = Provider<ProductImageStore>(
  (ref) => ProductImageStore(
    ref.watch(appDatabaseProvider),
    ref.watch(imageDirectoryProvider),
  ),
);

/// Rasm manbasi (fayl tanlash; testlarda almashtiriladi). `null` — bekor.
typedef ImageSourcePicker = Future<Uint8List?> Function();

Future<Uint8List?> _pickImageFile() async {
  final files = await FilePicker.pickFiles(type: FileType.image);
  if (files.isEmpty) return null;
  return files.first.readAsBytes();
}

final imageSourcePickerProvider = Provider<ImageSourcePicker>(
  (ref) => _pickImageFile,
);

/// Rasmni tayyorlash (isolate'da JPEG; testlarda almashtiriladi).
typedef ImagePreparer = Future<Uint8List> Function(Uint8List source);

final imagePreparerProvider = Provider<ImagePreparer>(
  (ref) => prepareProductImage,
);

/// Rasm sinxron holati (kartadagi "yuklanmagan" belgisi uchun).
final StreamProviderFamily<String?, String> productImageStateProvider =
    StreamProvider.autoDispose.family<String?, String>((ref, imageId) {
      final db = ref.watch(appDatabaseProvider);
      return (db.select(db.productImages)..where((i) => i.id.equals(imageId)))
          .watchSingleOrNull()
          .map((row) => row?.state);
    });

/// Rasm fayli (ko'rsatish uchun): bor bo'lsa — fayl, yo'q bo'lsa — `null`
/// (placeholder). Yuklab olingach qayta so'raladi.
final FutureProviderFamily<File?, String> productImageFileProvider =
    FutureProvider.autoDispose.family<File?, String>(
      (ref, imageId) => ref.watch(productImageStoreProvider).existing(imageId),
    );
