import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/sync_engine.dart';

/// Fon sinxroni holati.
class SyncStatus {
  const SyncStatus({
    this.health = SyncHealth.unknown,
    this.syncing = false,
    this.lastSuccessAt,
  });

  final SyncHealth health;
  final bool syncing;
  final DateTime? lastSuccessAt;

  SyncStatus copyWith({
    SyncHealth? health,
    bool? syncing,
    DateTime? lastSuccessAt,
  }) => SyncStatus(
    health: health ?? this.health,
    syncing: syncing ?? this.syncing,
    lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
  );
}

class SyncStatusController extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  // ignore: use_setters_to_change_properties — Notifier holati, xususiyat emas.
  void set(SyncStatus status) => state = status;
}

final syncStatusProvider = NotifierProvider<SyncStatusController, SyncStatus>(
  SyncStatusController.new,
);

/// Fon sinxronini o'chirish (testlarda — haqiqiy tarmoqqa chiqmaslik).
final syncEnabledProvider = Provider<bool>((ref) => true);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final tokens = ref.watch(deviceTokenStoreProvider);
  final dio = ref.watch(dioFactoryProvider);
  return SyncEngine(db, () async {
    final token = await tokens.read();
    return token == null ? null : deviceApi(dio, token);
  });
});

/// Fon sinxroni (`docs/specs/sync.md`): har 10 s push (va yangi hodisa
/// paydo bo'lganda darhol), har 60 s va push'dan keyin pull. Qurilma
/// ulangan bo'lsa ishlaydi (PIN ekranida ham — ma'lumot qamalib qolmaydi).
class SyncRunner extends ConsumerStatefulWidget {
  const SyncRunner({required this.child, super.key});

  static const Duration pushInterval = Duration(seconds: 10);
  static const Duration pullInterval = Duration(seconds: 60);

  /// Yangi hodisadan keyin kichik kechikish (bir nechta skanerni birlashtirish).
  static const Duration debounce = Duration(seconds: 1);

  final Widget child;

  @override
  ConsumerState<SyncRunner> createState() => _SyncRunnerState();
}

class _SyncRunnerState extends ConsumerState<SyncRunner> {
  Timer? _ticker;
  Timer? _soon;
  bool _running = false;
  DateTime? _lastPull;
  int _lastQueued = 0;

  bool get _active =>
      ref.read(syncEnabledProvider) &&
      ref.read(sessionProvider).device != null &&
      ref.read(sessionProvider).stage != SessionStage.initialSync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restart());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _soon?.cancel();
    super.dispose();
  }

  void _restart() {
    _ticker?.cancel();
    if (!mounted || !_active) return;
    _ticker = Timer.periodic(SyncRunner.pushInterval, (_) => _tick());
    unawaited(_tick());
  }

  void _schedule() {
    if (!_active) return;
    _soon?.cancel();
    _soon = Timer(SyncRunner.debounce, () => unawaited(_tick()));
  }

  Future<void> _tick() async {
    if (_running || !mounted || !_active) return;
    _running = true;
    final status = ref.read(syncStatusProvider.notifier)
      ..set(ref.read(syncStatusProvider).copyWith(syncing: true));
    try {
      final now = ref.read(clockProvider)();
      final last = _lastPull;
      final pull =
          last == null || now.difference(last) >= SyncRunner.pullInterval;
      final report = await ref.read(syncEngineProvider).syncOnce(pull: pull);
      if (!mounted) return;
      if (report.health == SyncHealth.online && pull) _lastPull = now;
      status.set(
        SyncStatus(
          health: report.health,
          lastSuccessAt: report.health == SyncHealth.online
              ? now
              : ref.read(syncStatusProvider).lastSuccessAt,
        ),
      );
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(sessionProvider, (previous, next) {
        if (previous?.stage != next.stage) _restart();
      })
      ..listen(pendingEventsProvider, (previous, next) {
        final count = next.value ?? 0;
        // Yangi hodisa — kutmasdan yuboramiz.
        if (count > _lastQueued) _schedule();
        _lastQueued = count;
      });
    return widget.child;
  }
}
