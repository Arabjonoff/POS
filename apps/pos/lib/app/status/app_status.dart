import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/outbox.dart';

/// Internet holati. Haqiqiy kuzatuv — sinxron dvigatelida (T-035).
enum ConnectionStatus { unknown, online, offline }

/// Printer holati. Haqiqiy tekshiruv — chek chop etishda (T-044).
enum PrinterStatus { unknown, ready, missing }

final connectionStatusProvider = Provider<ConnectionStatus>(
  (ref) => ConnectionStatus.unknown,
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
