import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PIN xeshini oflayn tekshirish (qaror 0006):
/// `pbkdf2_sha256$<iteratsiya>$<tuz>$<base64(PBKDF2-HMAC-SHA256, 32 bayt)>`
/// — Django `PBKDF2PasswordHasher` formati, server bilan bir xil
/// (`testdata/pin_hash.json`).
abstract final class PinHash {
  static const String algorithm = 'pbkdf2_sha256';

  /// PIN — 4–6 raqam.
  static const int minLength = 4;
  static const int maxLength = 6;

  /// Tekshiruv (120 000 iteratsiya) UI'ni to'xtatmasligi uchun alohida
  /// isolate'da.
  static Future<bool> verify(String pin, String encoded) =>
      Isolate.run(() => verifySync(pin, encoded));

  static bool verifySync(String pin, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != algorithm) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;
    final salt = parts[2];
    final List<int> expected;
    try {
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = pbkdf2Sha256(
      utf8.encode(pin),
      utf8.encode(salt),
      iterations,
      expected.length,
    );
    return _constantTimeEquals(actual, expected);
  }

  static String encode(String pin, String salt, int iterations) {
    final key = pbkdf2Sha256(
      utf8.encode(pin),
      utf8.encode(salt),
      iterations,
      32,
    );
    return '$algorithm\$$iterations\$$salt\$${base64.encode(key)}';
  }

  /// RFC 8018 PBKDF2 (PRF = HMAC-SHA256).
  static Uint8List pbkdf2Sha256(
    List<int> password,
    List<int> salt,
    int iterations,
    int length,
  ) {
    final hmac = Hmac(sha256, password);
    final out = Uint8List(length);
    var offset = 0;
    for (var block = 1; offset < length; block++) {
      final blockIndex = Uint8List(4)..buffer.asByteData().setUint32(0, block);
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      final take = (length - offset).clamp(0, t.length);
      out.setRange(offset, offset + take, t);
      offset += take;
    }
    return out;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
