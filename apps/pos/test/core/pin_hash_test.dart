import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/security/pin_hash.dart';

void main() {
  final data =
      jsonDecode(File('../../testdata/pin_hash.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (data['cases'] as List).cast<Map<String, dynamic>>();
  final encodedByPin = {
    for (final c in cases) c['pin'] as String: c['encoded'] as String,
  };

  test('RFC 6070-style PBKDF2-HMAC-SHA256 vector', () {
    // RFC 7914, 11-bo'lim: P="passwd", S="salt", c=1, dkLen=64.
    final key = PinHash.pbkdf2Sha256(
      utf8.encode('passwd'),
      utf8.encode('salt'),
      1,
      64,
    );
    expect(
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
      '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
    );
  });

  test('server vectors verify (testdata/pin_hash.json)', () {
    expect(data['iterations'], 120000);
    for (final c in cases) {
      expect(
        PinHash.verifySync(c['pin'] as String, c['encoded'] as String),
        isTrue,
        reason: c['pin'] as String,
      );
    }
  });

  test('encode reproduces server output', () {
    final c = cases.first;
    expect(
      PinHash.encode(c['pin'] as String, c['salt'] as String, 120000),
      c['encoded'],
    );
  });

  test('wrong PINs are rejected', () {
    for (final w in (data['wrong_pins'] as List).cast<Map<String, dynamic>>()) {
      expect(
        PinHash.verifySync(
          w['pin'] as String,
          encodedByPin[w['encoded_of'] as String]!,
        ),
        isFalse,
        reason: w['pin'] as String,
      );
    }
  });

  test('malformed hashes never verify', () {
    for (final bad in [
      '',
      r'argon2$1$s$AAAA',
      r'pbkdf2_sha256$x$s$AAAA',
      r'pbkdf2_sha256$1$s$!!!',
      r'pbkdf2_sha256$1$s',
    ]) {
      expect(PinHash.verifySync('1234', bad), isFalse, reason: bad);
    }
  });

  test('verify runs off the UI isolate', () async {
    final c = cases.first;
    expect(
      await PinHash.verify(c['pin'] as String, c['encoded'] as String),
      isTrue,
    );
  });
}
