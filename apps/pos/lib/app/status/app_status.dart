import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/sync/sync_runner.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/data/sync/sync_engine.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/shift/shift_providers.dart';

/// Internet holati — fon sinxronining oxirgi urinishi bo'yicha (haqiqiy
/// server bilan aloqa; Wi-Fi bor-yo'qligi emas).
enum ConnectionStatus { unknown, online, offline }

/// Printer holati: `unknown` — sozlanmagan, `checking` — ochilganda
/// tekshirilmoqda, keyin har chop etishdan so'ng `ready` / `missing`.
enum PrinterStatus { unknown, checking, ready, missing }

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
  (ref) => ref.watch(printerHealthProvider),
);

/// Serverga hali yuborilmagan yozuvlar soni.
final pendingEventsProvider = StreamProvider<int>(
  (ref) => ref.watch(appDatabaseProvider).watchPendingEventCount(),
);

/// Shu qurilmada ochiq smena bormi (kassa ekrani bilan bir manba).
final shiftOpenProvider = StreamProvider<bool>((ref) {
  final device = ref.watch(sessionProvider.select((s) => s.device));
  if (device == null) return Stream.value(false);
  return ref
      .watch(shiftServiceProvider)
      .watchCurrentShift(device.id)
      .map((shift) => shift != null);
});

/// Hozirgi vaqt manbai (testlarda qat'iy vaqt beriladi).
final clockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => clock.now(),
);
