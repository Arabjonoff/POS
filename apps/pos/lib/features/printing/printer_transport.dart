import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:pos_app/features/printing/android_printer_channel.dart';
import 'package:pos_app/features/printing/winspool.dart';

/// Printerga baytlarni yetkazish (ulanish turi bo'yicha). Xato bo'lsa —
/// istisno; chaqiruvchi uni savdoni to'xtatmaydigan xabarga aylantiradi.
abstract interface class PrinterTransport {
  Future<void> send(Uint8List bytes);

  /// Printer javob beradimi (tarmoq — ulanish ochiladi; Windows — printer
  /// tizimda bor).
  Future<bool> isReachable();
}

/// Tarmoq printeri: `IP:9100` (RAW). Barcha platformalarda ishlaydi.
class NetworkPrinterTransport implements PrinterTransport {
  NetworkPrinterTransport(
    this.host, {
    this.port = defaultPort,
    this.timeout = const Duration(seconds: 5),
  });

  /// `192.168.1.50` yoki `192.168.1.50:9100`.
  factory NetworkPrinterTransport.parse(String address) {
    final value = address.trim();
    final colon = value.lastIndexOf(':');
    if (colon > 0) {
      final port = int.tryParse(value.substring(colon + 1));
      if (port != null) {
        return NetworkPrinterTransport(value.substring(0, colon), port: port);
      }
    }
    return NetworkPrinterTransport(value);
  }

  static const int defaultPort = 9100;

  final String host;
  final int port;
  final Duration timeout;

  @override
  Future<void> send(Uint8List bytes) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    try {
      socket.add(bytes);
      await socket.flush().timeout(timeout);
    } finally {
      await socket.close().timeout(timeout, onTimeout: () => socket);
      socket.destroy();
    }
  }

  @override
  Future<bool> isReachable() async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } on Exception {
      return false;
    }
  }
}

/// Windows: tizimga o'rnatilgan printer (USB ham shu orqali), RAW rejimda.
class WindowsSpoolerTransport implements PrinterTransport {
  const WindowsSpoolerTransport(this.printerName);

  final String printerName;

  @override
  Future<void> send(Uint8List bytes) async =>
      Winspool.writeRaw(printerName, bytes);

  @override
  Future<bool> isReachable() async => Winspool.printers().contains(printerName);
}

/// Android: juftlangan Bluetooth printer (SPP) yoki USB printer (host).
/// Ruxsat so'rash va ulanish — native qatlamda (`PrinterChannel.kt`).
class AndroidPrinterTransport implements PrinterTransport {
  const AndroidPrinterTransport(
    this.kind,
    this.deviceId, {
    this.channel = const AndroidPrinterChannel(),
  });

  final AndroidPrinterKind kind;

  /// Bluetooth — MAC manzil; USB — `vendorId:productId`.
  final String deviceId;
  final AndroidPrinterChannel channel;

  @override
  Future<void> send(Uint8List bytes) => channel.send(kind, deviceId, bytes);

  @override
  Future<bool> isReachable() => channel.isAvailable(kind, deviceId);
}
