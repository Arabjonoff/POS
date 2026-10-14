import 'package:flutter/services.dart';
import 'package:pos_app/data/catalog/product_import.dart';
import 'package:pos_app/data/remote/api.dart';

/// Server o'rnida: chaqiruvlarni yozib oladi.
class FakeImportApi implements ProductImportApi {
  bool offline = false;
  ImportMapping? checked;
  ImportMapping? applied;
  String? appliedBy;

  static const ImportUpload sample = ImportUpload(
    id: 'imp-1',
    columns: ['Nomi', 'Kod', 'Narx', 'Izoh'],
    sample: [
      ['Non', '4780000000014', '4000', ''],
      ['Sut', '', '12000', 'yangi'],
    ],
    totalRows: 120,
    mapping: {
      ImportField.name: 0,
      ImportField.barcode: null,
      ImportField.category: null,
      ImportField.unit: null,
      ImportField.sellPrice: 2,
      ImportField.costPrice: null,
      ImportField.stock: null,
    },
  );

  @override
  Future<Uint8List> template() async {
    if (offline) throw const ApiFailure(ApiFailureKind.network);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<ImportUpload> upload(PickedFile file) async {
    if (offline) throw const ApiFailure(ApiFailureKind.network);
    return sample;
  }

  @override
  Future<ImportCheck> check(String id, ImportMapping mapping) async {
    checked = mapping;
    return const ImportCheck(
      creates: 100,
      updates: 18,
      errorCount: 2,
      errors: [
        ImportRowError(row: 5, field: 'sell_price', code: 'invalid_number'),
        ImportRowError(row: 9, field: 'barcode', code: 'invalid_check_digit'),
      ],
    );
  }

  @override
  Future<ImportResult> apply(
    String id,
    ImportMapping mapping, {
    required String by,
  }) async {
    applied = mapping;
    appliedBy = by;
    return const ImportResult(
      created: 100,
      updated: 18,
      skipped: 2,
      errorCount: 2,
      errors: [],
      receipt: 7,
    );
  }
}

class FakeFiles implements ImportFiles {
  String? savedName;

  @override
  Future<PickedFile?> pick() async =>
      PickedFile(name: 'tovarlar.xlsx', bytes: Uint8List.fromList([0]));

  @override
  Future<bool> save(String name, Uint8List bytes) async {
    savedName = name;
    return true;
  }
}
