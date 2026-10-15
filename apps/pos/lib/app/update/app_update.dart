import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';

/// Lokal sozlama: serverdagi oxirgi versiya (pull'dan, JSON yoki bo'sh).
const String appReleaseSettingKey = 'app_release';

/// Yangi versiya haqida (T-093, `docs/RELEASE.md`).
@immutable
class AppUpdate {
  const AppUpdate({required this.latestVersion, required this.downloadUrl});

  final String latestVersion;

  /// Bo'sh bo'lishi mumkin — unda "administrator bilan bog'laning".
  final String downloadUrl;

  @override
  bool operator ==(Object other) =>
      other is AppUpdate &&
      other.latestVersion == latestVersion &&
      other.downloadUrl == downloadUrl;

  @override
  int get hashCode => Object.hash(latestVersion, downloadUrl);
}

/// `1.2.3` (`+build`, `-beta` e'tiborsiz) → `[1, 2, 3]`; noto'g'ri — `null`.
List<int>? parseVersion(String value) {
  final core = value.trim().split(RegExp('[+-]')).first;
  final parts = core.split('.');
  if (parts.isEmpty || parts.length > 3) return null;
  final numbers = [for (final p in parts) int.tryParse(p)];
  if (numbers.any((n) => n == null || n < 0)) return null;
  return [...numbers.cast<int>(), ...List.filled(3 - numbers.length, 0)];
}

/// [latest] [current] dan yangiroqmi.
bool isNewer(String latest, String current) {
  final a = parseVersion(latest);
  final b = parseVersion(current);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// Pull'dagi `app` → saqlanadigan qiymat.
String encodeRelease(String? latestVersion, String? downloadUrl) =>
    latestVersion == null || latestVersion.isEmpty
    ? ''
    : jsonEncode({
        'latest_version': latestVersion,
        'download_url': downloadUrl ?? '',
      });

/// O'rnatilgan versiya (`--dart-define=POS_APP_VERSION`).
final installedVersionProvider = Provider<String>(
  (ref) => ApiConfig.appVersion,
);

/// Server yangiroq versiya e'lon qilgan bo'lsa — [AppUpdate].
final appUpdateProvider = StreamProvider<AppUpdate?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final installed = ref.watch(installedVersionProvider);
  return (db.select(db.localSettings)
        ..where((t) => t.key.equals(appReleaseSettingKey)))
      .watchSingleOrNull()
      .map((row) {
        final raw = row?.value ?? '';
        if (raw.isEmpty) return null;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final latest = json['latest_version'] as String? ?? '';
        if (!isNewer(latest, installed)) return null;
        return AppUpdate(
          latestVersion: latest,
          downloadUrl: json['download_url'] as String? ?? '',
        );
      });
});
