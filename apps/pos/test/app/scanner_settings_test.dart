import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/scanner/scanner_settings.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/data/db/app_database.dart';

import '../helpers/sqlite.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  ProviderContainer container({ScannerSettings? initial}) {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (initial != null)
          initialScannerSettingsProvider.overrideWithValue(initial),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('defaults: sound on, 35 ms', () async {
    final s = await ScannerSettings.load(db);
    expect(s.sound, isTrue);
    expect(s.intervalMs, 35);
  });

  test('interval is applied to the scanner and saved', () async {
    final c = container();
    expect(
      c.read(scannerServiceProvider).maxInterval,
      const Duration(milliseconds: 35),
    );
    await c.read(scannerSettingsProvider.notifier).setInterval(100);
    expect(
      c.read(scannerServiceProvider).maxInterval,
      const Duration(milliseconds: 100),
    );
    expect((await ScannerSettings.load(db)).intervalMs, 100);
  });

  test('saved interval is applied at start-up', () async {
    final c = container(initial: const ScannerSettings(intervalMs: 60))
      ..read(scannerSettingsProvider);
    expect(
      c.read(scannerServiceProvider).maxInterval,
      const Duration(milliseconds: 60),
    );
  });

  test('sound can be muted', () async {
    final c = container();
    expect(c.read(scanSignalProvider).enabled, isTrue);
    await c.read(scannerSettingsProvider.notifier).setSound(enabled: false);
    expect(c.read(scanSignalProvider).enabled, isFalse);
    expect((await ScannerSettings.load(db)).sound, isFalse);
  });

  test('unknown saved interval falls back to 35 ms', () async {
    await db.writeSetting('scanner_interval_ms', '7');
    expect((await ScannerSettings.load(db)).intervalMs, 35);
  });
}
