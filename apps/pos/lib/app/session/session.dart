import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/device/device_info.dart';
import 'package:pos_app/data/remote/api.dart';

/// Ilova bosqichi.
enum SessionStage {
  /// Qurilma ulanmagan: ega telefon + parol → qurilma nomi.
  setup,

  /// Qurilma ulangan, birinchi sinxron tugamagan (uzilishdan keyin davom).
  initialSync,

  /// Kassir tanlash + PIN.
  locked,

  /// Ishlash rejimi.
  unlocked,
}

class Session {
  const Session({required this.stage, this.device, this.user});

  final SessionStage stage;
  final DeviceInfo? device;

  /// Kirgan xodim (faqat `unlocked` da).
  final StaffUser? user;
}

/// Ilova ochilishida (`main`): token va qurilma ma'lumotidan bosqich.
final initialSessionProvider = Provider<Session>(
  (ref) => const Session(stage: SessionStage.setup),
);

const String _initialSyncDoneKey = 'initial_sync_done';

Future<Session> loadSession(AppDatabase db, DeviceTokenStore tokens) async {
  final token = await tokens.read();
  final device = await DeviceInfo.load(db);
  if (token == null || device == null) {
    return const Session(stage: SessionStage.setup);
  }
  final synced = await db.readSetting(_initialSyncDoneKey) == '1';
  return Session(
    stage: synced ? SessionStage.locked : SessionStage.initialSync,
    device: device,
  );
}

class SessionController extends Notifier<Session> {
  @override
  Session build() => ref.read(initialSessionProvider);

  /// Qurilma ro'yxatdan o'tdi → birinchi sinxron.
  void deviceRegistered(DeviceInfo device) =>
      state = Session(stage: SessionStage.initialSync, device: device);

  /// Birinchi sinxron tugadi → qulf ekrani.
  Future<void> initialSyncDone() async {
    await ref.read(appDatabaseProvider).writeSetting(_initialSyncDoneKey, '1');
    state = Session(stage: SessionStage.locked, device: state.device);
  }

  void unlock(StaffUser user) => state = Session(
    stage: SessionStage.unlocked,
    device: state.device,
    user: user,
  );

  void lock() {
    if (state.stage != SessionStage.unlocked) return;
    state = Session(stage: SessionStage.locked, device: state.device);
  }
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);
