import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('settings can be written, read and overwritten', () async {
    expect(await db.readSetting('locale'), isNull);
    await db.writeSetting('locale', 'uz');
    expect(await db.readSetting('locale'), 'uz');
    await db.writeSetting('locale', 'ru');
    expect(await db.readSetting('locale'), 'ru');
  });
}
