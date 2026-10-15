import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/printing/android_printer_channel.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/printer_transport.dart';

import '../helpers/fake_android_printer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAndroidPrinter native;
  const channel = AndroidPrinterChannel();
  final bytes = Uint8List.fromList([0x1B, 0x40, 0x41, 0x0A]);

  setUp(() {
    native = FakeAndroidPrinter()
      ..bluetooth = [
        {'id': '66:22:B3:01:9A:10', 'name': 'XP-P323B'},
        {'id': '00:11:22:33:44:55', 'name': ''},
      ]
      ..usb = [
        {'id': '1046:20497', 'name': 'Xprinter XP-58'},
      ]
      ..install();
  });

  test('lists paired Bluetooth and attached USB printers', () async {
    final bt = await channel.devices(AndroidPrinterKind.bluetooth);
    expect(bt.map((d) => d.id), ['66:22:B3:01:9A:10', '00:11:22:33:44:55']);
    expect(bt.first.name, 'XP-P323B');
    final usb = await channel.devices(AndroidPrinterKind.usb);
    expect(usb.single.id, '1046:20497');
  });

  test('native error codes become clear problems', () async {
    for (final (code, problem) in [
      ('bluetooth_off', AndroidPrinterProblem.bluetoothOff),
      ('permission_denied', AndroidPrinterProblem.permissionDenied),
      ('io', AndroidPrinterProblem.other),
    ]) {
      native.listError = code;
      await expectLater(
        channel.devices(AndroidPrinterKind.bluetooth),
        throwsA(
          isA<AndroidPrinterException>().having(
            (e) => e.problem,
            'problem',
            problem,
          ),
        ),
      );
    }
  });

  test(
    'transport sends the exact ESC/POS bytes to the chosen device',
    () async {
      await const AndroidPrinterTransport(
        AndroidPrinterKind.bluetooth,
        '66:22:B3:01:9A:10',
      ).send(bytes);
      await const AndroidPrinterTransport(
        AndroidPrinterKind.usb,
        '1046:20497',
      ).send(bytes);
      expect(native.jobs.map((j) => (j.$1, j.$2)), [
        ('bluetoothSend', '66:22:B3:01:9A:10'),
        ('usbSend', '1046:20497'),
      ]);
      expect(native.jobs.every((j) => listEquals(j.$3, bytes)), isTrue);
    },
  );

  test('printer off: send throws an Exception (service turns it into '
      '"not printed"), reachability is false', () async {
    native.sendError = 'io';
    const transport = AndroidPrinterTransport(
      AndroidPrinterKind.bluetooth,
      '66:22:B3:01:9A:10',
    );
    await expectLater(transport.send(bytes), throwsA(isA<Exception>()));
    expect(await transport.isReachable(), isFalse);
  });

  test('reachable only when the device is paired / attached', () async {
    expect(
      await const AndroidPrinterTransport(
        AndroidPrinterKind.bluetooth,
        '66:22:B3:01:9A:10',
      ).isReachable(),
      isTrue,
    );
    expect(
      await const AndroidPrinterTransport(
        AndroidPrinterKind.usb,
        '1:2',
      ).isReachable(),
      isFalse,
    );
  });

  test('no native side (desktop): not reachable, send fails softly', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidPrinterChannel.channel, null);
    const transport = AndroidPrinterTransport(AndroidPrinterKind.usb, '1:2');
    expect(await transport.isReachable(), isFalse);
    await expectLater(
      transport.send(bytes),
      throwsA(isA<AndroidPrinterException>()),
    );
  });

  test('settings pick the Android transport; device name survives JSON', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final factory = container.read(printerTransportFactoryProvider);
    const bt = PrinterSettings(
      connection: PrinterConnection.bluetooth,
      address: '66:22:B3:01:9A:10',
      deviceName: 'XP-P323B',
    );
    final transport = factory(bt)! as AndroidPrinterTransport;
    expect(transport.kind, AndroidPrinterKind.bluetooth);
    expect(transport.deviceId, '66:22:B3:01:9A:10');
    expect(
      (factory(
                const PrinterSettings(
                  connection: PrinterConnection.usb,
                  address: '1046:20497',
                ),
              )!
              as AndroidPrinterTransport)
          .kind,
      AndroidPrinterKind.usb,
    );
    expect(
      factory(const PrinterSettings(connection: PrinterConnection.usb)),
      isNull,
    );

    final restored = PrinterSettings.fromJson(bt.toJson());
    expect(restored.connection, PrinterConnection.bluetooth);
    expect(restored.deviceName, 'XP-P323B');
    // Eski JSON (T-044) — device_name yo'q.
    expect(
      PrinterSettings.fromJson(const {
        'connection': 'network',
        'address': '1.2.3.4',
      }).deviceName,
      '',
    );
  });
}
