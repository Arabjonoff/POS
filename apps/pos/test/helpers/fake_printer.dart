import 'dart:io';
import 'dart:typed_data';

import 'package:pos_app/features/printing/printer_transport.dart';

/// Yuborilgan ishlarni yozib oladi; [fail] — printer o'chiq.
class FakeTransport implements PrinterTransport {
  final List<Uint8List> jobs = [];
  bool fail = false;

  @override
  Future<void> send(Uint8List bytes) async {
    if (fail) throw const SocketException('offline');
    jobs.add(bytes);
  }

  @override
  Future<bool> isReachable() async => !fail;
}

/// [bytes] ichida [part] ketma-ketligi bormi.
bool containsBytes(List<int> bytes, List<int> part) {
  for (var i = 0; i + part.length <= bytes.length; i++) {
    var match = true;
    for (var j = 0; j < part.length; j++) {
      if (bytes[i + j] != part[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
