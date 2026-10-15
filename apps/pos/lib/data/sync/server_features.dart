import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';

/// Server e'lon qilgan imkoniyatlar (pull javobidagi `features`).
///
/// Yangi turdagi hodisa faqat server uni bilsa yuboriladi: eski server
/// `unknown_event` bilan rad etsa, kassa qoldig'i server bilan farq qilib
/// qoladi (CLAUDE.md 10-qoida).
const String serverFeaturesSettingKey = 'server_features';

abstract final class ServerFeature {
  /// Kirimni tahrirlash va bekor qilish (`receipt.corrected`, `receipt.reversed`).
  static const String receiptCorrections = 'receipt_corrections';

  /// Chek rekvizitlarini kassadan o'zgartirish (`store.upserted`).
  static const String storeSettings = 'store_settings';
}

String encodeFeatures(List<String>? features) => jsonEncode(features ?? []);

Set<String> decodeFeatures(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  final value = jsonDecode(raw);
  return value is List ? {for (final f in value) '$f'} : const {};
}

final serverFeaturesProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.localSettings)
        ..where((t) => t.key.equals(serverFeaturesSettingKey)))
      .watchSingleOrNull()
      .map((row) => decodeFeatures(row?.value));
});
