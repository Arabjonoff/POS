import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Skaner sozlamalari (`LocalSettings`).
class ScannerSettings {
  const ScannerSettings({this.sound = true, this.intervalMs = 35});

  /// Skanerlashda ovoz/vibratsiya.
  final bool sound;

  /// HID skaner belgilari orasidagi eng katta interval (ms).
  final int intervalMs;

  static const List<int> intervalOptions = [35, 60, 100];

  static const String _soundKey = 'scanner_sound';
  static const String _intervalKey = 'scanner_interval_ms';

  static Future<ScannerSettings> load(AppDatabase db) async {
    final interval = int.tryParse(await db.readSetting(_intervalKey) ?? '');
    return ScannerSettings(
      sound: await db.readSetting(_soundKey) != '0',
      intervalMs: intervalOptions.contains(interval) ? interval! : 35,
    );
  }

  ScannerSettings copyWith({bool? sound, int? intervalMs}) => ScannerSettings(
    sound: sound ?? this.sound,
    intervalMs: intervalMs ?? this.intervalMs,
  );
}

/// `main` da bazadan o'qiladi.
final initialScannerSettingsProvider = Provider<ScannerSettings>(
  (ref) => const ScannerSettings(),
);

class ScannerSettingsController extends Notifier<ScannerSettings> {
  @override
  ScannerSettings build() {
    final settings = ref.read(initialScannerSettingsProvider);
    _apply(settings);
    return settings;
  }

  void _apply(ScannerSettings s) =>
      ref.read(scannerServiceProvider).maxInterval = Duration(
        milliseconds: s.intervalMs,
      );

  Future<void> setSound({required bool enabled}) async {
    state = state.copyWith(sound: enabled);
    await ref
        .read(appDatabaseProvider)
        .writeSetting(ScannerSettings._soundKey, enabled ? '1' : '0');
  }

  Future<void> setInterval(int ms) async {
    state = state.copyWith(intervalMs: ms);
    _apply(state);
    await ref
        .read(appDatabaseProvider)
        .writeSetting(ScannerSettings._intervalKey, '$ms');
  }
}

final scannerSettingsProvider =
    NotifierProvider<ScannerSettingsController, ScannerSettings>(
      ScannerSettingsController.new,
    );

/// Skanerlash signali: muvaffaqiyat — qisqa "bip" + yengil vibratsiya;
/// topilmadi/xato — boshqa ovoz + kuchli vibratsiya (`barcode.md`).
/// Rang chaqnashi — `PosScanFeedback` (ekranda).
class ScanSignal {
  const ScanSignal({required this.enabled});

  final bool enabled;

  Future<void> success() async {
    if (!enabled) return;
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
  }

  Future<void> notFound() async {
    if (!enabled) return;
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
  }
}

final scanSignalProvider = Provider<ScanSignal>(
  (ref) => ScanSignal(enabled: ref.watch(scannerSettingsProvider).sound),
);
