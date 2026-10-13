import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Lokal sozlamalar (kalit → qiymat). Biznes jadvallari T-032 da qo'shiladi.
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [LocalSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Qurilmadagi doimiy baza fayli (`pos.sqlite`).
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'pos'));

  @override
  int get schemaVersion => 1;

  Future<String?> readSetting(String key) async {
    final row = await (select(
      localSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) {
    return into(
      localSettings,
    ).insertOnConflictUpdate(LocalSetting(key: key, value: value));
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
