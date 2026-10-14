import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../../helpers/sqlite.dart';
import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

/// Eski versiyadagi kassa bazasi yangi ilovada to'g'ri yangilanadi
/// (sxema suratlari: `drift_schemas/`, `dart run drift_dev make-migrations`).
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    setUpTestSqlite();
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('every version upgrades to every later version', () {
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('v1 → v2 keeps saved settings (language)', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.localSettings, [
          const v1.LocalSettingsData(key: 'locale', value: 'uz_Cyrl'),
        ]);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.localSettings).get(), const [
          v2.LocalSettingsData(key: 'locale', value: 'uz_Cyrl'),
        ]);
        // Yangi jadvallar bo'sh va ishlaydi.
        expect(await newDb.select(newDb.outboxEvents).get(), isEmpty);
      },
    );
  });

  test('schema version matches the latest snapshot', () {
    final db = openTestDatabase();
    addTearDown(db.close);
    expect(db.schemaVersion, GeneratedHelper.versions.last);
  });
}
