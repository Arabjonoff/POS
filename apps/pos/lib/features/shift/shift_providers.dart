import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, StreamProviderFamily;
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/shifts/shift_service.dart';

final shiftServiceProvider = Provider<ShiftService>(
  (ref) => ShiftService(ref.watch(appDatabaseProvider)),
);

/// Shu qurilmaning ochiq smenasi (`null` — yopiq; savdo yo'q).
final currentShiftProvider = StreamProvider<Shift?>((ref) {
  final device = ref.watch(sessionProvider.select((s) => s.device));
  if (device == null) return Stream.value(null);
  return ref.watch(shiftServiceProvider).watchCurrentShift(device.id);
});

/// Ochiq smenaning X hisoboti (har o'zgarishda — bazadagi savdolar).
final FutureProviderFamily<ShiftReport, String> shiftReportProvider =
    FutureProvider.autoDispose.family<ShiftReport, String>(
      (ref, shiftId) => ref.watch(shiftServiceProvider).report(shiftId),
    );

/// Smenadagi kassa puli harakatlari (yangisi birinchi).
final StreamProviderFamily<List<CashMovement>, String> cashMovementsProvider =
    StreamProvider.autoDispose.family<List<CashMovement>, String>(
      (ref, shiftId) => ref.watch(shiftServiceProvider).watchMovements(shiftId),
    );
