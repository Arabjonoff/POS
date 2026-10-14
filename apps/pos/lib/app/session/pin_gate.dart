import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/security/pin_hash.dart';
import 'package:pos_app/data/db/app_database.dart';

sealed class PinResult {
  const PinResult();
}

class PinAccepted extends PinResult {
  const PinAccepted();
}

class PinRejected extends PinResult {
  const PinRejected(this.attemptsLeft);

  final int attemptsLeft;
}

class PinLockedOut extends PinResult {
  const PinLockedOut(this.remaining);

  final Duration remaining;
}

class PinNotSet extends PinResult {
  const PinNotSet();
}

typedef PinVerifier = Future<bool> Function(String pin, String encoded);

/// PIN tekshiruvi (oflayn): 5 marta xato → 1 daqiqa kutish. Hisoblagich
/// lokal bazada — ilovani qayta ochib chetlab o'tib bo'lmaydi.
class PinGate {
  PinGate(this._db, {DateTime Function()? now, PinVerifier? verify})
    : _now = now ?? _clockNow,
      _verify = verify ?? PinHash.verify;

  static const int maxAttempts = 5;
  static const Duration lockout = Duration(minutes: 1);

  static const String _failuresKey = 'pin_failures';
  static const String _lockedUntilKey = 'pin_locked_until';

  final AppDatabase _db;
  final DateTime Function() _now;
  final PinVerifier _verify;

  /// Qolgan kutish vaqti yoki `null`.
  Future<Duration?> lockedFor() async {
    final until = DateTime.tryParse(
      await _db.readSetting(_lockedUntilKey) ?? '',
    );
    if (until == null) return null;
    final left = until.difference(_now());
    return left > Duration.zero ? left : null;
  }

  Future<PinResult> check(StaffUser user, String pin) async {
    final locked = await lockedFor();
    if (locked != null) return PinLockedOut(locked);
    final hash = user.pinHash;
    if (hash == null || hash.isEmpty) return const PinNotSet();

    if (await _verify(pin, hash)) {
      await _db.writeSetting(_failuresKey, '0');
      return const PinAccepted();
    }
    final failures =
        (int.tryParse(await _db.readSetting(_failuresKey) ?? '') ?? 0) + 1;
    if (failures >= maxAttempts) {
      await _db.transaction(() async {
        await _db.writeSetting(_failuresKey, '0');
        await _db.writeSetting(
          _lockedUntilKey,
          _now().toUtc().add(lockout).toIso8601String(),
        );
      });
      return const PinLockedOut(lockout);
    }
    await _db.writeSetting(_failuresKey, '$failures');
    return PinRejected(maxAttempts - failures);
  }
}

final pinGateProvider = Provider<PinGate>(
  (ref) => PinGate(ref.watch(appDatabaseProvider)),
);

/// Joriy vaqt (testlarda flutter_test soxta vaqti).
DateTime _clockNow() => clock.now();
