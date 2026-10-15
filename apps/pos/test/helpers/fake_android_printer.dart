import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/printing/android_printer_channel.dart';

/// Native printer kanali (`PrinterChannel.kt`) o'rnida: qurilmalar ro'yxati,
/// yuborilgan ishlar, xato kodlari. `install` — test oxirida o'zi tozalanadi.
class FakeAndroidPrinter {
  List<Map<String, String>> bluetooth = [];
  List<Map<String, String>> usb = [];

  /// Ro'yxat so'ralganda qaytariladigan xato kodi (`bluetooth_off` ...).
  String? listError;

  /// Yuborishdagi xato kodi (printer o'chiq — `io`).
  String? sendError;

  final List<MethodCall> calls = [];

  /// `(usul, qurilma, baytlar)`.
  final List<(String, String, Uint8List)> jobs = [];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidPrinterChannel.channel, _handle);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AndroidPrinterChannel.channel, null),
    );
  }

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    final args = (call.arguments as Map<Object?, Object?>?) ?? const {};
    final id = args['id'] as String? ?? '';
    switch (call.method) {
      case 'bluetoothDevices':
      case 'usbDevices':
        if (listError != null) {
          throw PlatformException(code: listError!, message: 'fake');
        }
        return call.method == 'bluetoothDevices' ? bluetooth : usb;
      case 'bluetoothSend':
      case 'usbSend':
        if (sendError != null) {
          throw PlatformException(code: sendError!, message: 'fake');
        }
        jobs.add((call.method, id, args['bytes']! as Uint8List));
        return null;
      case 'bluetoothAvailable':
        return sendError == null && bluetooth.any((d) => d['id'] == id);
      case 'usbAvailable':
        return sendError == null && usb.any((d) => d['id'] == id);
    }
    throw MissingPluginException(call.method);
  }
}
