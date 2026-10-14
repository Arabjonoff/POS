import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/app/sync/sync_runner.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/data/sync/sync_engine.dart';

/// Nima uchun savdo (va kirim) to'xtatilgan. Ko'rish, hisobot va sinxron
/// har doim ishlaydi — ma'lumot qamalib qolmaydi (`docs/specs/sync.md`).
enum SalesBlock {
  none,

  /// Obuna muddati tugagan (`readonly`).
  readonly,

  /// Do'kon bloklangan (`blocked`).
  blocked,

  /// Server bilan oxirgi aloqadan beri `offline_days` o'tdi.
  offlineTooLong,

  /// Qurilma bloklangan.
  deviceBlocked,
}

final syncStateProvider = StreamProvider<SyncStateData?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.syncState).watchSingleOrNull();
});

final deviceBlockedProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.localSettings)
        ..where((t) => t.key.equals(SyncEngine.deviceBlockedKey)))
      .watchSingleOrNull()
      .map((row) => row?.value == '1');
});

/// Savdo ruxsati: obuna holati, oflayn muddati, qurilma bloki.
final salesBlockProvider = Provider<SalesBlock>((ref) {
  // Sinxron holati o'zgarganda (har 10 s) qayta hisoblanadi — oflayn
  // muddati ilova ochiq turganda ham o'tishi mumkin.
  ref.watch(syncStatusProvider);
  if (ref.watch(deviceBlockedProvider).value ?? false) {
    return SalesBlock.deviceBlocked;
  }
  final state = ref.watch(syncStateProvider).value;
  if (state == null) return SalesBlock.none;
  final json = state.subscriptionJson;
  if (json != null) {
    final status = (jsonDecode(json) as Map<String, dynamic>)['status'];
    if (status == 'blocked') return SalesBlock.blocked;
    if (status == 'readonly') return SalesBlock.readonly;
  }
  final grace = state.offlineGraceUntil;
  if (grace != null) {
    // Qurilma soati noto'g'ri bo'lishi mumkin — server farqi bilan tuzatiladi.
    final serverNow = ref
        .watch(clockProvider)()
        .add(Duration(milliseconds: state.serverTimeOffsetMs));
    if (serverNow.isAfter(grace)) return SalesBlock.offlineTooLong;
  }
  return SalesBlock.none;
});

final salesAllowedProvider = Provider<bool>(
  (ref) => ref.watch(salesBlockProvider) == SalesBlock.none,
);

/// Qurilma soati serverdan 5 daqiqadan ko'p farq qiladi.
final clockSkewProvider = Provider<bool>((ref) {
  final offset = ref.watch(syncStateProvider).value?.serverTimeOffsetMs ?? 0;
  return offset.abs() > const Duration(minutes: 5).inMilliseconds;
});

/// Server rad etgan (qayta yuborilmaydigan) yozuvlar soni.
final rejectedEventsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final count = db.outboxEvents.id.count();
  return (db.selectOnly(db.outboxEvents)
        ..addColumns([count])
        ..where(db.outboxEvents.status.equals(OutboxStatus.rejected)))
      .map((row) => row.read(count) ?? 0)
      .watchSingle();
});
