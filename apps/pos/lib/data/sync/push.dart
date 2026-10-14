import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:pos_api_client/pos_api_client.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/outbox.dart';

/// Bitta paket natijasi.
class PushBatchResult {
  const PushBatchResult({
    required this.sent,
    required this.rejected,
    required this.remaining,
    this.serverTime,
  });

  /// Server qabul qilgan (applied / duplicate / pending).
  final int sent;

  /// Server rad etgan (qayta yuborilmaydi).
  final int rejected;

  /// Navbatda hali yuborish vaqti kelgan hodisalar bormi.
  final bool remaining;
  final DateTime? serverTime;
}

/// Outbox → `POST /sync/push/` (`docs/specs/sync.md`, `sync-api.md`).
///
/// - Bir qurilma hodisalari `created_at` tartibida, 100 tadan.
/// - Server `id` bo'yicha idempotent: tarmoq uzilib javob kelmasa — o'sha
///   hodisalar o'sha ID bilan qayta yuboriladi, dublikat bo'lmaydi.
/// - `applied` / `duplicate` / `pending` → yuborilgan; `rejected` → xato
///   saqlanadi, qayta yuborilmaydi (admin ko'radi).
/// - Tarmoq/server xatosida: eksponensial kutish 5 s → 5 daq.
class OutboxPusher {
  OutboxPusher(this._db, this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const int batchSize = 100;
  static const Duration minBackoff = Duration(seconds: 5);
  static const Duration maxBackoff = Duration(minutes: 5);

  final AppDatabase _db;
  final PosApi _api;
  final DateTime Function() _now;

  /// `attempts` marta muvaffaqiyatsiz bo'lgandan keyingi kutish.
  static Duration backoff(int attempts) {
    final factor = math.pow(2, math.max(0, attempts - 1)).toInt();
    final ms = minBackoff.inMilliseconds * factor;
    return Duration(milliseconds: math.min(ms, maxBackoff.inMilliseconds));
  }

  /// Navbat boshidan [limit] ta hodisa. Eng eski hodisaning kutish vaqti
  /// kelmagan bo'lsa — hech narsa (tartib buzilmasin: yangisi eskisidan
  /// oldin ketmaydi).
  Future<List<OutboxEvent>> _due(int limit) async {
    final events =
        await (_db.select(_db.outboxEvents)
              ..where((e) => e.status.equals(OutboxStatus.pending))
              ..orderBy([
                (e) => OrderingTerm(expression: e.createdAt),
                (e) => OrderingTerm(expression: e.id),
              ])
              ..limit(limit))
            .get();
    final wait = events.firstOrNull?.nextAttemptAt;
    if (wait != null && wait.isAfter(_now())) return const [];
    return events;
  }

  /// Keyingi urinish vaqti (navbat boshi kutayotgan bo'lsa).
  Future<DateTime?> nextAttemptAt() async {
    final first =
        await (_db.select(_db.outboxEvents)
              ..where((e) => e.status.equals(OutboxStatus.pending))
              ..orderBy([
                (e) => OrderingTerm(expression: e.createdAt),
                (e) => OrderingTerm(expression: e.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return first?.nextAttemptAt;
  }

  /// Bitta paket. Tarmoq/server xatosida [ApiFailure] tashlanadi (paketdagi
  /// hodisalarga kutish belgilangandan keyin).
  Future<PushBatchResult> pushBatch() async {
    final events = await _due(batchSize);
    if (events.isEmpty) {
      return const PushBatchResult(sent: 0, rejected: 0, remaining: false);
    }

    final PushResponse response;
    try {
      response = await _api.sync.syncPushCreate(
        body: PushRequestRequest(
          events: [
            for (final e in events)
              EventRequest(
                id: e.id,
                type: e.type,
                payload: jsonDecode(e.payload) as Map<String, dynamic>,
                createdAt: e.createdAt.toUtc(),
              ),
          ],
        ),
      );
    } on Object catch (error) {
      final failure = ApiFailure.from(error);
      await _postpone(events, failure);
      throw failure;
    }

    final byId = {for (final r in response.results) r.id: r};
    var sent = 0;
    var rejected = 0;
    final now = _now();
    await _db.transaction(() async {
      for (final event in events) {
        final result = byId[event.id];
        final query = _db.update(_db.outboxEvents)
          ..where((e) => e.id.equals(event.id));
        switch (result?.status) {
          case EventResultStatusEnum.applied ||
              EventResultStatusEnum.duplicate ||
              EventResultStatusEnum.pending:
            sent++;
            await query.write(
              OutboxEventsCompanion(
                status: const Value(OutboxStatus.sent),
                sentAt: Value(now),
                attempts: Value(event.attempts + 1),
                lastError: const Value(null),
              ),
            );
          case EventResultStatusEnum.rejected:
            rejected++;
            final error = result!.error;
            await query.write(
              OutboxEventsCompanion(
                status: const Value(OutboxStatus.rejected),
                attempts: Value(event.attempts + 1),
                lastError: Value(
                  error == null
                      ? 'rejected'
                      : '${error.code}: ${error.message}',
                ),
              ),
            );
          case EventResultStatusEnum.$unknown || null:
            // Javobda yo'q yoki noma'lum holat — keyinroq qayta yuboramiz.
            await query.write(
              OutboxEventsCompanion(
                attempts: Value(event.attempts + 1),
                nextAttemptAt: Value(now.add(backoff(event.attempts + 1))),
              ),
            );
        }
      }
      await _db
          .into(_db.syncState)
          .insertOnConflictUpdate(
            SyncStateCompanion.insert(
              id: const Value(1),
              lastPushAt: Value(now),
            ),
          );
    });
    final more = (await _due(1)).isNotEmpty;
    return PushBatchResult(
      sent: sent,
      rejected: rejected,
      remaining: more,
      serverTime: response.serverTime,
    );
  }

  Future<void> _postpone(List<OutboxEvent> events, ApiFailure failure) async {
    final now = _now();
    await _db.transaction(() async {
      for (final event in events) {
        final attempts = event.attempts + 1;
        await (_db.update(
          _db.outboxEvents,
        )..where((e) => e.id.equals(event.id))).write(
          OutboxEventsCompanion(
            attempts: Value(attempts),
            lastError: Value(failure.code ?? failure.kind.name),
            nextAttemptAt: Value(now.add(backoff(attempts))),
          ),
        );
      }
    });
  }
}
