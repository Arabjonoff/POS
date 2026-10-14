import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/sync/sync_runner.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/data/sync/sync_engine.dart';

/// Internet holati — fon sinxronining oxirgi urinishi bo'yicha (haqiqiy
/// server bilan aloqa; Wi-Fi bor-yo'qligi emas).
enum ConnectionStatus { unknown, online, offline }

/// Printer holati. Haqiqiy tekshiruv — chek chop etishda (T-044).
enum PrinterStatus { unknown, ready, missing }

final connectionStatusProvider = Provider<ConnectionStatus>(
  (ref) => switch (ref.watch(syncStatusProvider).health) {
    SyncHealth.unknown => ConnectionStatus.unknown,
    SyncHealth.online => ConnectionStatus.online,
    SyncHealth.offline ||
    SyncHealth.unauthorized ||
    SyncHealth.deviceBlocked => ConnectionStatus.offline,
  },
);

final printerStatusProvider = Provider<PrinterStatus>(
  (ref) => PrinterStatus.unknown,
);

/// Serverga hali yuborilmagan yozuvlar soni.
final pendingEventsProvider = StreamProvider<int>(
  (ref) => ref.watch(appDatabaseProvider).watchPendingEventCount(),
);

/// Shu qurilmada ochiq smena bormi.
final shiftOpenProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final count = db.shifts.id.count();
  return (db.selectOnly(db.shifts)
        ..addColumns([count])
        ..where(db.shifts.closedAt.isNull()))
      .map((row) => (row.read(count) ?? 0) > 0)
      .watchSingle();
});

/// Hozirgi vaqt manbai (testlarda qat'iy vaqt beriladi).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
