import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:pos_api_client/pos_api_client.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/data/sync/pull.dart';
import 'package:pos_app/data/sync/push.dart';

/// Server bilan aloqa holati (oxirgi urinish bo'yicha).
enum SyncHealth {
  /// Hali urinilmagan.
  unknown,

  /// Server javob berdi.
  online,

  /// Internet yo'q yoki server javob bermadi.
  offline,

  /// Qurilma tokeni yaroqsiz (401) — qayta ulash kerak.
  unauthorized,

  /// Qurilma bloklangan (403 `device_blocked`).
  deviceBlocked,
}

class SyncReport {
  const SyncReport({
    required this.health,
    this.pushed = 0,
    this.rejected = 0,
    this.pulled = 0,
  });

  final SyncHealth health;
  final int pushed;
  final int rejected;
  final int pulled;
}

/// Bitta sinxron sikli: avval hamma navbat (push, 100 tadan), keyin pull.
/// Hech qachon tashlamaydi — natija [SyncReport.health] da.
class SyncEngine {
  SyncEngine(this._db, this._api, {DateTime Function()? now})
    : _now = now ?? _clockNow;

  static const String deviceBlockedKey = 'device_blocked';

  /// Bir siklda ko'pi bilan shuncha paket (10 000 hodisa) — qolgani keyingi
  /// siklda (UI'ni band qilmaslik uchun).
  static const int maxBatches = 100;

  final AppDatabase _db;

  /// Qurilma tokeni bilan API; token yo'q bo'lsa `null`.
  final Future<PosApi?> Function() _api;
  final DateTime Function() _now;

  Future<SyncReport> syncOnce({bool pull = true}) async {
    final api = await _api();
    if (api == null) return const SyncReport(health: SyncHealth.unauthorized);

    var pushed = 0;
    var rejected = 0;
    var pulled = 0;
    try {
      final pusher = OutboxPusher(_db, api, now: _now);
      for (var i = 0; i < maxBatches; i++) {
        final result = await pusher.pushBatch();
        pushed += result.sent;
        rejected += result.rejected;
        if (!result.remaining) break;
      }
      // Javobi yo'qolgan paket qayta yuborilishini kutayotgan bo'lsa — pull
      // qilinmaydi: server ularni allaqachon qo'llagan bo'lishi mumkin, u holda
      // pull qoldig'i ularni o'z ichiga oladi, kassa esa ularni hali yuborilmagan
      // deb yana qo'shadi (qoldiq ikki marta) va kirim narxini eski narx bosadi
      // (audit RC-B5/B6). Navbat bo'shagach pull odatdagidek.
      if (pull && !await _awaitingRetry()) {
        pulled = await SyncPuller(
          _db,
          api,
          applier: PullApplier(_db, now: _now),
        ).pullAll();
      }
      await _db.writeSetting(deviceBlockedKey, '0');
      return SyncReport(
        health: SyncHealth.online,
        pushed: pushed,
        rejected: rejected,
        pulled: pulled,
      );
    } on Object catch (error) {
      final failure = ApiFailure.from(error);
      final health = switch ((failure.kind, failure.code)) {
        (ApiFailureKind.unauthorized, _) => SyncHealth.unauthorized,
        (_, 'device_blocked') => SyncHealth.deviceBlocked,
        _ => SyncHealth.offline,
      };
      if (health == SyncHealth.deviceBlocked) {
        await _db.writeSetting(deviceBlockedKey, '1');
      }
      return SyncReport(
        health: health,
        pushed: pushed,
        rejected: rejected,
        pulled: pulled,
      );
    }
  }
}

extension on SyncEngine {
  Future<bool> _awaitingRetry() async {
    final row =
        await (_db.select(_db.outboxEvents)
              ..where(
                (e) =>
                    e.status.equals(OutboxStatus.pending) &
                    e.attempts.isBiggerThanValue(0),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }
}

/// Joriy vaqt (testlarda flutter_test soxta vaqti).
DateTime _clockNow() => clock.now();
