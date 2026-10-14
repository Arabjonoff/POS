import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_api_client/pos_api_client.dart';
import 'package:pos_app/app/sync/sync_runner.dart';
import 'package:pos_app/data/remote/api.dart';

/// Import ustunlari (`docs/specs/product-import.md`).
enum ImportField {
  name('name'),
  barcode('barcode'),
  category('category'),
  unit('unit'),
  sellPrice('sell_price'),
  costPrice('cost_price'),
  stock('stock')
  ;

  const ImportField(this.code);

  final String code;

  /// Majburiy maydonlar — nom va narx.
  bool get required => this == name || this == sellPrice;

  static ImportField? fromCode(String code) =>
      values.where((f) => f.code == code).firstOrNull;
}

/// Maydon → ustun indeksi (`null` — yo'q).
typedef ImportMapping = Map<ImportField, int?>;

Map<String, int?> mappingToJson(ImportMapping m) => {
  for (final f in ImportField.values) f.code: m[f],
};

ImportMapping mappingFromJson(Map<String, Object?> json) => {
  for (final f in ImportField.values) f: json[f.code] as int?,
};

class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class ImportUpload {
  const ImportUpload({
    required this.id,
    required this.columns,
    required this.sample,
    required this.totalRows,
    required this.mapping,
  });

  final String id;
  final List<String> columns;
  final List<List<String>> sample;
  final int totalRows;
  final ImportMapping mapping;
}

class ImportRowError {
  const ImportRowError({
    required this.row,
    required this.field,
    required this.code,
  });

  /// Excel qator raqami (sarlavha — 1).
  final int row;
  final String field;
  final String code;
}

class ImportCheck {
  const ImportCheck({
    required this.creates,
    required this.updates,
    required this.errorCount,
    required this.errors,
  });

  final int creates;
  final int updates;
  final int errorCount;
  final List<ImportRowError> errors;
}

class ImportResult {
  const ImportResult({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errorCount,
    required this.errors,
    this.receipt,
  });

  final int created;
  final int updated;
  final int skipped;
  final int errorCount;
  final List<ImportRowError> errors;

  /// Boshlang'ich qoldiq kirimining raqami.
  final int? receipt;
}

/// Server bilan ishlash (qurilma tokeni). Xato — [ApiFailure].
abstract interface class ProductImportApi {
  Future<Uint8List> template();
  Future<ImportUpload> upload(PickedFile file);
  Future<ImportCheck> check(String id, ImportMapping mapping);
  Future<ImportResult> apply(
    String id,
    ImportMapping mapping, {
    required String by,
  });
}

List<ImportRowError> _errors(List<RowError> rows) => [
  for (final e in rows)
    ImportRowError(row: e.row, field: e.field, code: e.code),
];

class _DeviceImportApi implements ProductImportApi {
  _DeviceImportApi(this._token, this._dio);

  final Future<String?> Function() _token;
  final DioFactory _dio;

  Future<Dio> _client() async {
    final token = await _token();
    if (token == null) throw const ApiFailure(ApiFailureKind.unauthorized);
    return _dio('Device $token');
  }

  Future<T> _call<T>(Future<T> Function(Dio dio) run) async {
    try {
      return await run(await _client());
    } on Object catch (e) {
      throw ApiFailure.from(e);
    }
  }

  @override
  Future<Uint8List> template() => _call((dio) async {
    final response = await dio.get<List<int>>(
      '/api/v1/sync/product-import/template/',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  });

  @override
  Future<ImportUpload> upload(PickedFile file) => _call((dio) async {
    final response = await dio.post<Map<String, Object?>>(
      '/api/v1/sync/product-imports/',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
      }),
    );
    final body = UploadResponse.fromJson(response.data!);
    return ImportUpload(
      id: body.id,
      columns: body.columns,
      sample: body.sample,
      totalRows: body.totalRows,
      mapping: mappingFromJson(body.mapping.toJson()),
    );
  });

  @override
  Future<ImportCheck> check(String id, ImportMapping mapping) =>
      _call((dio) async {
        final body = await PosApi(dio).sync.syncProductImportsCheckCreate(
          id: id,
          body: CheckRequestRequest(
            mapping: MappingRequest.fromJson(mappingToJson(mapping)),
          ),
        );
        return ImportCheck(
          creates: body.creates,
          updates: body.updates,
          errorCount: body.errorCount,
          errors: _errors(body.errors),
        );
      });

  @override
  Future<ImportResult> apply(
    String id,
    ImportMapping mapping, {
    required String by,
  }) => _call((dio) async {
    final body = await PosApi(dio).sync.syncProductImportsApplyCreate(
      id: id,
      body: ApplyRequestRequest(
        mapping: MappingRequest.fromJson(mappingToJson(mapping)),
        by: by,
      ),
    );
    return ImportResult(
      created: body.created,
      updated: body.updated,
      skipped: body.skipped,
      errorCount: body.errorCount,
      errors: _errors(body.errors),
      receipt: body.receipt,
    );
  });
}

final productImportApiProvider = Provider<ProductImportApi>((ref) {
  final tokens = ref.watch(deviceTokenStoreProvider);
  return _DeviceImportApi(tokens.read, ref.watch(dioFactoryProvider));
});

/// Fayl tanlash va saqlash (testlarda almashtiriladi).
abstract interface class ImportFiles {
  Future<PickedFile?> pick();

  /// `false` — foydalanuvchi bekor qildi.
  Future<bool> save(String name, Uint8List bytes);
}

class _PlatformImportFiles implements ImportFiles {
  const _PlatformImportFiles();

  @override
  Future<PickedFile?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv'],
    );
    if (files.isEmpty) return null;
    final file = files.first;
    return PickedFile(name: file.name, bytes: await file.readAsBytes());
  }

  @override
  Future<bool> save(String name, Uint8List bytes) async =>
      await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      ) !=
      null;
}

final importFilesProvider = Provider<ImportFiles>(
  (ref) => const _PlatformImportFiles(),
);

/// Importdan keyin katalogni darhol olish (pull).
final refreshCatalogProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(syncEngineProvider).syncOnce(),
);
