import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/printer_transport.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_loader.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

/// Chop etish natijasi. Hech biri savdoni to'xtatmaydi (`printing.md`).
enum PrintOutcome { printed, notConfigured, failed }

/// Chek, test chek, pul qutisi. Printer drayveri — [PrinterTransport].
class PrinterService {
  PrinterService({
    required this.settings,
    required this.transport,
    required this.loader,
    required this.l10n,
    required AppDatabase db,
    this.onResult,
  }) : _db = db;

  final PrinterSettings settings;

  /// `null` — printer sozlanmagan.
  final PrinterTransport? transport;
  final ReceiptLoader loader;
  final AppLocalizations l10n;
  final AppDatabase _db;

  /// Har urinishdan keyin (holat qatori uchun).
  final void Function(PrintOutcome outcome)? onResult;

  ReceiptBuilder get _builder => ReceiptBuilder(l10n, width: settings.width);

  /// Savdo cheki ([copy] — qayta chop etilgan "NUSXA"). Pul qutisi —
  /// sozlamada yoqilgan va naqd to'lov bo'lsa (nusxada emas).
  Future<PrintOutcome> printSale(String saleId, {bool copy = false}) async {
    final data = await loader.load(saleId);
    if (data == null) return PrintOutcome.failed;
    final drawer =
        !copy &&
        settings.openDrawer &&
        data.payments.any((p) => p.method == 'cash');
    final rows = _builder.build(data, copy: copy);
    final copies = copy ? 1 : settings.copies;
    return _send([
      for (var i = 0; i < copies; i++)
        EscPos.receipt(
          rows,
          encoding: settings.encoding,
          drawer: drawer && i == 0,
        ),
    ]);
  }

  /// Oxirgi savdo chekini qayta chop etish ("har doim mavjud").
  Future<PrintOutcome> reprintLast() async {
    final id = await lastSaleId();
    if (id == null) return PrintOutcome.failed;
    return printSale(id, copy: true);
  }

  Future<String?> lastSaleId() async {
    final last =
        await (_db.select(_db.sales)
              ..orderBy([(s) => OrderingTerm.desc(s.soldAt)])
              ..limit(1))
            .getSingleOrNull();
    return last?.id;
  }

  /// Test chek: kenglik chizg'ichi, vaqt va lotin/kirill sinovi.
  Future<PrintOutcome> printTest() async {
    final w = settings.width.chars;
    ReceiptRow center(String text, {bool bold = false}) =>
        ReceiptRow(text, bold: bold, center: true);
    final rows = [
      center(l10n.printerTestTitle, bold: true),
      ReceiptRow('-' * w),
      ReceiptRow(List.generate(w, (i) => '${(i + 1) % 10}').join()),
      center(AppFormat(l10n).dateTime(clock.now())),
      ReceiptRow('-' * w),
      for (final text in [l10n.printerTestSample, l10n.printerTestOk])
        for (final part in ReceiptBuilder.wrap(ReceiptBuilder.plain(text), w))
          center(part),
    ];
    return _send([EscPos.receipt(rows, encoding: settings.encoding)]);
  }

  Future<PrintOutcome> openDrawer() => _send([EscPos.drawerOnly()]);

  Future<PrintOutcome> _send(List<Uint8List> jobs) async {
    final t = transport;
    if (t == null) {
      onResult?.call(PrintOutcome.notConfigured);
      return PrintOutcome.notConfigured;
    }
    try {
      for (final job in jobs) {
        await t.send(job);
      }
      onResult?.call(PrintOutcome.printed);
      return PrintOutcome.printed;
    } on Exception {
      onResult?.call(PrintOutcome.failed);
      return PrintOutcome.failed;
    }
  }
}

/// Sozlamadan uzatish qatlami (testlarda soxtasi bilan almashtiriladi).
final printerTransportFactoryProvider =
    Provider<PrinterTransport? Function(PrinterSettings)>(
      (ref) =>
          (settings) => !settings.configured
          ? null
          : switch (settings.connection) {
              PrinterConnection.network => NetworkPrinterTransport.parse(
                settings.address,
              ),
              PrinterConnection.windows => WindowsSpoolerTransport(
                settings.address,
              ),
              PrinterConnection.none => null,
            },
    );

final printerServiceProvider = Provider<PrinterService>((ref) {
  final settings =
      ref.watch(printerSettingsProvider).value ?? const PrinterSettings();
  return PrinterService(
    settings: settings,
    transport: ref.watch(printerTransportFactoryProvider)(settings),
    loader: ref.watch(receiptLoaderProvider),
    l10n: lookupAppLocalizations(ref.watch(localeProvider)),
    db: ref.watch(appDatabaseProvider),
    onResult: (outcome) =>
        ref.read(printerHealthProvider.notifier).report(outcome),
  );
});

/// Sozlangan printerning holati: ochilganda tekshiriladi, keyin har chop
/// etishdan so'ng yangilanadi.
class PrinterHealth extends Notifier<PrinterStatus> {
  @override
  PrinterStatus build() {
    final settings = ref.watch(printerSettingsProvider).value;
    if (settings == null || !settings.configured) return PrinterStatus.unknown;
    final transport = ref.watch(printerTransportFactoryProvider)(settings);
    if (transport == null) return PrinterStatus.unknown;
    unawaited(_check(transport));
    return PrinterStatus.checking;
  }

  Future<void> _check(PrinterTransport transport) async {
    final ok = await transport.isReachable();
    if (!ref.mounted || state != PrinterStatus.checking) return;
    state = ok ? PrinterStatus.ready : PrinterStatus.missing;
  }

  void report(PrintOutcome outcome) {
    state = switch (outcome) {
      PrintOutcome.printed => PrinterStatus.ready,
      PrintOutcome.failed => PrinterStatus.missing,
      PrintOutcome.notConfigured => PrinterStatus.unknown,
    };
  }
}

final printerHealthProvider = NotifierProvider<PrinterHealth, PrinterStatus>(
  PrinterHealth.new,
);
