import 'fake_server.dart';

/// Serverning sinxron qismini taqlid qiladi: push — `id` bo'yicha idempotent
/// (`sync-api.md`), pull — berilgan sahifalar.
class FakeSyncServer {
  FakeSyncServer() {
    http
      ..on('POST /api/v1/sync/push/', _push)
      ..on('GET /api/v1/sync/pull/', _pull);
  }

  final FakeServer http = FakeServer();

  /// Qabul qilingan hodisalar (id → type), tartib bilan.
  final Map<String, String> applied = {};

  /// Har push so'rovidagi hodisalar soni.
  final List<int> batchSizes = [];

  /// `true` — so'rov serverga yetmaydi (internet yo'q).
  bool offline = false;

  /// `true` — server qo'llaydi, lekin javob yo'qoladi (keyingi so'rovgacha).
  bool loseNextResponse = false;

  /// Shu turdagi hodisalar rad etiladi.
  final Set<String> rejectTypes = {};

  /// HTTP status bilan javob (masalan, 403 device_blocked).
  (int, Object?)? forcedError;

  String subscriptionStatus = 'active';
  int offlineDays = 7;
  String serverTime = '2026-10-14T10:00:00Z';
  int pulls = 0;

  (int, Object?)? _push(RecordedRequest r) {
    if (offline) return null;
    if (forcedError != null) return forcedError;
    final events = ((r.body! as Map)['events'] as List)
        .cast<Map<String, dynamic>>();
    batchSizes.add(events.length);
    final results = <Map<String, Object?>>[];
    for (final e in events) {
      final id = e['id'] as String;
      final type = e['type'] as String;
      if (rejectTypes.contains(type)) {
        results.add({
          'id': id,
          'status': 'rejected',
          'error': {
            'code': 'invalid_sale',
            'message': 'bad',
            'details': <String, Object?>{},
          },
        });
      } else if (applied.containsKey(id)) {
        results.add({'id': id, 'status': 'duplicate'});
      } else {
        applied[id] = type;
        results.add({'id': id, 'status': 'applied'});
      }
    }
    if (loseNextResponse) {
      loseNextResponse = false;
      return null;
    }
    return (200, {'results': results, 'server_time': serverTime});
  }

  (int, Object?)? _pull(RecordedRequest r) {
    if (offline) return null;
    if (forcedError != null) return forcedError;
    pulls++;
    return (
      200,
      {
        'changes': <Object>[],
        'next_cursor': 'c$pulls',
        'has_more': false,
        'subscription': {
          'status': subscriptionStatus,
          'paid_until': null,
          'days_left': null,
          'offline_days': offlineDays,
        },
        'server_time': serverTime,
      },
    );
  }
}
