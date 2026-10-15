import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Android'dagi printer qurilmasi (Bluetooth — juftlangan, USB — ulangan).
class AndroidPrinterDevice {
  const AndroidPrinterDevice({required this.id, required this.name});

  factory AndroidPrinterDevice.fromMap(Map<Object?, Object?> map) =>
      AndroidPrinterDevice(
        id: map['id']! as String,
        name: (map['name'] as String?) ?? '',
      );

  /// Bluetooth — MAC manzil (`66:22:B3:01:9A:10`); USB — `vendorId:productId`
  /// (qayta ulanganda o'zgarmaydi).
  final String id;
  final String name;
}

/// Qurilmalar ro'yxatini olishdagi xato (sozlamalarda tushunarli xabar).
enum AndroidPrinterProblem {
  /// Bluetooth o'chiq yoki qurilmada yo'q.
  bluetoothOff('bluetooth_off'),

  /// Foydalanuvchi ruxsat bermadi (Android 12+ `BLUETOOTH_CONNECT`, USB).
  permissionDenied('permission_denied'),
  other('error')
  ;

  const AndroidPrinterProblem(this.code);

  final String code;

  static AndroidPrinterProblem fromCode(String code) =>
      values.firstWhere((p) => p.code == code, orElse: () => other);
}

class AndroidPrinterException implements Exception {
  const AndroidPrinterException(this.problem, [this.message]);

  final AndroidPrinterProblem problem;
  final String? message;

  @override
  String toString() => 'AndroidPrinterException(${problem.code}, $message)';
}

enum AndroidPrinterKind { bluetooth, usb }

/// Native qatlam (`MainActivity` → `PrinterChannel.kt`) bilan aloqa:
/// Bluetooth SPP (RFCOMM) va USB host (bulk OUT). Baytlar — tayyor ESC/POS.
class AndroidPrinterChannel {
  const AndroidPrinterChannel([this._channel = channel]);

  static const MethodChannel channel = MethodChannel('uz.zellypos.pos/printer');

  final MethodChannel _channel;

  /// Juftlangan Bluetooth qurilmalar yoki ulangan USB qurilmalar.
  Future<List<AndroidPrinterDevice>> devices(AndroidPrinterKind kind) =>
      _call(() async {
        final list = await _channel.invokeListMethod<Object?>(
          '${kind.name}Devices',
        );
        return [
          for (final item in list ?? const <Object?>[])
            AndroidPrinterDevice.fromMap(item! as Map<Object?, Object?>),
        ];
      });

  Future<void> send(AndroidPrinterKind kind, String id, Uint8List bytes) =>
      _call(
        () => _channel.invokeMethod<void>('${kind.name}Send', {
          'id': id,
          'bytes': bytes,
        }),
      );

  /// Bluetooth yoqiq va printer juftlangan / USB printer ulangan.
  Future<bool> isAvailable(AndroidPrinterKind kind, String id) async {
    try {
      return await _channel.invokeMethod<bool>('${kind.name}Available', {
            'id': id,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<T> _call<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (e) {
      throw AndroidPrinterException(
        AndroidPrinterProblem.fromCode(e.code),
        e.message,
      );
    } on MissingPluginException catch (e) {
      throw AndroidPrinterException(AndroidPrinterProblem.other, e.message);
    }
  }
}

/// Bluetooth/USB tanlovi faqat Android'da (testlarda almashtiriladi).
final androidPrintingProvider = Provider<bool>((ref) => Platform.isAndroid);

final androidPrinterChannelProvider = Provider<AndroidPrinterChannel>(
  (ref) => const AndroidPrinterChannel(),
);

/// Sozlamalardagi qurilmalar ro'yxati (yangilash — `ref.invalidate`).
final FutureProviderFamily<List<AndroidPrinterDevice>, AndroidPrinterKind>
androidPrintersProvider = FutureProvider.autoDispose
    .family<List<AndroidPrinterDevice>, AndroidPrinterKind>(
      (ref, kind) => ref.watch(androidPrinterChannelProvider).devices(kind),
    );
