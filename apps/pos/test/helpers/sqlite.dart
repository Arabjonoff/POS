import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:sqlite3/open.dart';

/// `flutter test` xostida SQLite kutubxonasini ochadi.
/// Windows'da tizimdagi `winsqlite3.dll` ishlatiladi (sqlite3.dll ilova bilan birga keladi,
/// lekin test xostida yo'q). Linux/macOS'da tizim kutubxonasi.
void setUpTestSqlite() {
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}

AppDatabase openTestDatabase() {
  setUpTestSqlite();
  return AppDatabase(NativeDatabase.memory());
}
