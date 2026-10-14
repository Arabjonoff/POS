import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/sales/sale_writer.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/payment/checkout.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/printer_transport.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_loader.dart';
import 'package:pos_app/features/printing/winspool.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

import '../helpers/fake_printer.dart';
import '../helpers/sqlite.dart';

void main() {
  final uz = lookupAppLocalizations(AppLocales.uzLatn);
  late AppDatabase db;
  late FakeTransport transport;
  final outcomes = <PrintOutcome>[];

  setUp(() async {
    db = openTestDatabase();
    transport = FakeTransport();
    outcomes.clear();
    await db
        .into(db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: 'shift-1',
            storeId: 'store-1',
            deviceId: 'device-1',
            openedBy: 'cashier-1',
            openedAt: DateTime.utc(2026, 10, 15, 8),
            openingCashTiyin: 0,
          ),
        );
  });
  tearDown(() => db.close());

  Future<String> sell({PayMode mode = PayMode.cash}) async {
    const cart = Cart(
      id: 'cart',
      slot: 0,
      lines: [
        CartLine(
          id: 'l1',
          productId: 'p-non',
          name: 'Non',
          unit: 'pcs',
          qtyMilli: 1000,
          priceTiyin: 400000,
          costTiyin: 300000,
        ),
      ],
    );
    final done = await Checkout(SaleWriter(db, deviceNumber: 3)).complete(
      cart: cart,
      payment: PaymentDraft(totalTiyin: cart.totalTiyin, mode: mode),
      shiftId: 'shift-1',
      cashierId: 'cashier-1',
    );
    return done.sale.id;
  }

  PrinterService service(
    PrinterSettings settings, {
    bool configured = true,
  }) => PrinterService(
    settings: settings,
    transport: configured ? transport : null,
    loader: ReceiptLoader(db),
    l10n: uz,
    db: db,
    onResult: outcomes.add,
  );

  test('sale receipt: copies, drawer only on the first copy of cash', () async {
    final id = await sell();
    final result = await service(
      const PrinterSettings(copies: 2, openDrawer: true),
    ).printSale(id);
    expect(result, PrintOutcome.printed);
    expect(transport.jobs, hasLength(2));
    expect(containsBytes(transport.jobs[0], EscPos.openDrawer), isTrue);
    expect(containsBytes(transport.jobs[1], EscPos.openDrawer), isFalse);
    expect(containsBytes(transport.jobs[0], EscPos.feedAndCut), isTrue);
    expect(outcomes, [PrintOutcome.printed]);
  });

  test('card sale does not open the drawer', () async {
    final id = await sell(mode: PayMode.card);
    await service(const PrinterSettings(openDrawer: true)).printSale(id);
    expect(containsBytes(transport.jobs.single, EscPos.openDrawer), isFalse);
  });

  test('reprint: last sale, marked as a copy, one job', () async {
    await sell();
    final last = await sell();
    final s = service(const PrinterSettings(copies: 3, openDrawer: true));
    expect(await s.lastSaleId(), last);
    expect(await s.reprintLast(), PrintOutcome.printed);
    final job = transport.jobs.single;
    expect(
      containsBytes(job, EscPos.encode(uz.receiptCopy, PrinterEncoding.cp866)),
      isTrue,
    );
    expect(containsBytes(job, EscPos.openDrawer), isFalse);
  });

  test('printer off → failed, nothing thrown; not configured', () async {
    final id = await sell();
    transport.fail = true;
    expect(
      await service(const PrinterSettings()).printSale(id),
      PrintOutcome.failed,
    );
    expect(
      await service(const PrinterSettings(), configured: false).printSale(id),
      PrintOutcome.notConfigured,
    );
    expect(outcomes, [PrintOutcome.failed, PrintOutcome.notConfigured]);
  });

  test('test receipt fits the paper; drawer command alone', () async {
    final s = service(const PrinterSettings(width: PaperWidth.mm80));
    expect(await s.printTest(), PrintOutcome.printed);
    expect(
      containsBytes(
        transport.jobs.single,
        EscPos.encode(uz.printerTestTitle, PrinterEncoding.cp866),
      ),
      isTrue,
    );
    await s.openDrawer();
    expect(transport.jobs.last, EscPos.drawerOnly());
  });

  test('settings: JSON round trip, copies clamped, bad input → defaults', () {
    const settings = PrinterSettings(
      connection: PrinterConnection.network,
      address: '192.168.1.50:9100',
      width: PaperWidth.mm80,
      encoding: PrinterEncoding.utf8,
      autoPrint: false,
      copies: 2,
      openDrawer: true,
    );
    final back = PrinterSettings.fromJson(settings.toJson());
    expect(back.toJson(), settings.toJson());
    expect(back.configured, isTrue);
    expect(PrinterSettings.fromJson(const {'copies': 9}).copies, 3);
    expect(const PrinterSettings().configured, isFalse);
  });

  group('network printer', () {
    test('bytes reach IP:port', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final received = Completer<List<int>>();
      server.listen((client) async {
        final bytes = <int>[];
        await client.forEach(bytes.addAll);
        // isReachable ulanishi bo'sh — e'tiborsiz.
        if (bytes.isNotEmpty) received.complete(bytes);
      });
      final t = NetworkPrinterTransport.parse('127.0.0.1:${server.port}');
      expect(t.port, server.port);
      expect(await t.isReachable(), isTrue);
      await t.send(Uint8List.fromList([1, 2, 3]));
      expect(await received.future, [1, 2, 3]);
    });

    test('nobody listening → error, not reachable', () async {
      final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = free.port;
      await free.close();
      final t = NetworkPrinterTransport(
        '127.0.0.1',
        port: port,
        timeout: const Duration(seconds: 1),
      );
      expect(await t.isReachable(), isFalse);
      await expectLater(t.send(Uint8List(1)), throwsA(isA<SocketException>()));
    });

    test('address without a port → 9100', () {
      expect(NetworkPrinterTransport.parse(' 10.0.0.7 ').port, 9100);
      expect(NetworkPrinterTransport.parse('10.0.0.7').host, '10.0.0.7');
    });
  });

  test('windows spooler: lists printers; unknown printer → error', () async {
    if (!Platform.isWindows) {
      expect(Winspool.printers(), isEmpty);
      return;
    }
    expect(Winspool.printers(), isA<List<String>>());
    const t = WindowsSpoolerTransport("POS test: printer yo'q 0x7f");
    expect(await t.isReachable(), isFalse);
    await expectLater(
      t.send(Uint8List(1)),
      throwsA(isA<WinspoolException>()),
    );
  });
}
