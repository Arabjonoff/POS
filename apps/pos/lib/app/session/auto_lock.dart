import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/device/device_info.dart';

/// Avtomatik qulflash variantlari (daqiqa; 0 — o'chiq).
const List<int> autoLockOptions = [0, 2, 5, 10, 30];
const int defaultAutoLockMinutes = 5;

/// `main` da bazadan o'qiladi.
final initialAutoLockMinutesProvider = Provider<int>(
  (ref) => defaultAutoLockMinutes,
);

class AutoLockController extends Notifier<int> {
  @override
  int build() => ref.read(initialAutoLockMinutesProvider);

  Future<void> select(int minutes) async {
    state = minutes;
    await ref
        .read(appDatabaseProvider)
        .writeSetting(SettingKeys.autoLockMinutes, '$minutes');
  }
}

final autoLockMinutesProvider = NotifierProvider<AutoLockController, int>(
  AutoLockController.new,
);

Future<int> loadAutoLockMinutes(AppDatabase db) async =>
    int.tryParse(await db.readSetting(SettingKeys.autoLockMinutes) ?? '') ??
    defaultAutoLockMinutes;

/// Ekranga tegish yoki tugma bosilmasa — belgilangan vaqtdan keyin qulf.
/// Skaner ham klaviatura sifatida keladi, demak savdo paytida qulflanmaydi.
class AutoLock extends ConsumerStatefulWidget {
  const AutoLock({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AutoLock> createState() => _AutoLockState();
}

class _AutoLockState extends ConsumerState<AutoLock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    _timer?.cancel();
    final minutes = ref.read(autoLockMinutesProvider);
    final unlocked = ref.read(sessionProvider).stage == SessionStage.unlocked;
    if (minutes <= 0 || !unlocked) return;
    _timer = Timer(
      Duration(minutes: minutes),
      () => ref.read(sessionProvider.notifier).lock(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(sessionProvider, (_, _) => _restart())
      ..listen(autoLockMinutesProvider, (_, _) => _restart());
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      child: widget.child,
    );
  }
}
