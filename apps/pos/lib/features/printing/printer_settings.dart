import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/winspool.dart';

/// Printer ulanishi (qaror 0008): tarmoq — hamma joyda, Windows spooler,
/// Android'da Bluetooth (SPP) va USB (T-047).
enum PrinterConnection {
  none('none'),
  network('network'),
  windows('windows'),
  bluetooth('bluetooth'),
  usb('usb')
  ;

  const PrinterConnection(this.code);

  final String code;

  static PrinterConnection fromCode(String? code) =>
      values.firstWhere((c) => c.code == code, orElse: () => none);
}

/// Kassa qurilmasining printer sozlamalari (`printing.md`). Lokal bazada
/// (`local_settings`, kalit [settingKey]) — har kassada o'zi.
class PrinterSettings {
  const PrinterSettings({
    this.connection = PrinterConnection.none,
    this.address = '',
    this.deviceName = '',
    this.width = PaperWidth.mm58,
    this.encoding = PrinterEncoding.cp866,
    this.autoPrint = true,
    this.copies = 1,
    this.openDrawer = false,
    this.codePage = EscPos.defaultCodePage,
    this.cancelKanji = true,
    this.cut = true,
    this.feedLines = 4,
  });

  /// Eski JSON (yangi kalitlarsiz) — standart qiymatlar bilan o'qiladi.
  factory PrinterSettings.fromJson(Map<String, Object?> json) =>
      PrinterSettings(
        connection: PrinterConnection.fromCode(json['connection'] as String?),
        address: json['address'] as String? ?? '',
        deviceName: json['device_name'] as String? ?? '',
        width: switch ((json['width'], json['chars'])) {
          (80, 42) => PaperWidth.mm80narrow,
          (80, _) => PaperWidth.mm80,
          _ => PaperWidth.mm58,
        },
        encoding: PrinterEncoding.fromCode(json['encoding'] as String?),
        autoPrint: json['auto_print'] as bool? ?? true,
        copies: ((json['copies'] as int?) ?? 1).clamp(1, maxCopies),
        openDrawer: json['open_drawer'] as bool? ?? false,
        codePage: ((json['code_page'] as int?) ?? EscPos.defaultCodePage).clamp(
          0,
          255,
        ),
        cancelKanji: json['cancel_kanji'] as bool? ?? true,
        cut: json['cut'] as bool? ?? true,
        feedLines: ((json['feed_lines'] as int?) ?? 4).clamp(0, maxFeedLines),
      );

  static const String settingKey = 'printer';
  static const int maxCopies = 3;
  static const int maxFeedLines = 10;

  final PrinterConnection connection;

  /// Tarmoq — `IP[:port]`; Windows — printer nomi; Bluetooth — MAC manzil;
  /// USB — `vendorId:productId`.
  final String address;

  /// Tanlangan Bluetooth/USB qurilma nomi (sozlamalarda ko'rsatish uchun).
  final String deviceName;
  final PaperWidth width;
  final PrinterEncoding encoding;

  /// Savdo yakunlanganda chek avtomatik chiqadi.
  final bool autoPrint;
  final int copies;

  /// Naqd to'lovda pul qutisini ochish.
  final bool openDrawer;

  /// `ESC t n` (PC866 raqami printer modeliga bog'liq).
  final int codePage;

  /// `FS .` — xitoycha rejimni o'chirish.
  final bool cancelKanji;
  final bool cut;
  final int feedLines;

  bool get configured =>
      connection != PrinterConnection.none && address.trim().isNotEmpty;

  EscPosProfile get profile => EscPosProfile(
    encoding: encoding,
    codePage: codePage,
    cancelKanji: cancelKanji,
    cut: cut,
    feedLines: feedLines,
  );

  Map<String, Object?> toJson() => {
    'connection': connection.code,
    'address': address,
    'device_name': deviceName,
    'width': width.mm,
    'chars': width.chars,
    'encoding': encoding.code,
    'auto_print': autoPrint,
    'copies': copies,
    'open_drawer': openDrawer,
    'code_page': codePage,
    'cancel_kanji': cancelKanji,
    'cut': cut,
    'feed_lines': feedLines,
  };

  PrinterSettings copyWith({
    PrinterConnection? connection,
    String? address,
    String? deviceName,
    PaperWidth? width,
    PrinterEncoding? encoding,
    bool? autoPrint,
    int? copies,
    bool? openDrawer,
    int? codePage,
    bool? cancelKanji,
    bool? cut,
    int? feedLines,
  }) => PrinterSettings(
    connection: connection ?? this.connection,
    address: address ?? this.address,
    deviceName: deviceName ?? this.deviceName,
    width: width ?? this.width,
    encoding: encoding ?? this.encoding,
    autoPrint: autoPrint ?? this.autoPrint,
    copies: (copies ?? this.copies).clamp(1, maxCopies),
    openDrawer: openDrawer ?? this.openDrawer,
    codePage: (codePage ?? this.codePage).clamp(0, 255),
    cancelKanji: cancelKanji ?? this.cancelKanji,
    cut: cut ?? this.cut,
    feedLines: (feedLines ?? this.feedLines).clamp(0, maxFeedLines),
  );
}

class PrinterSettingsController extends AsyncNotifier<PrinterSettings> {
  @override
  Future<PrinterSettings> build() async {
    final raw = await ref
        .watch(appDatabaseProvider)
        .readSetting(PrinterSettings.settingKey);
    if (raw == null) return const PrinterSettings();
    try {
      return PrinterSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return const PrinterSettings();
    }
  }

  Future<void> save(PrinterSettings settings) async {
    state = AsyncData(settings);
    await ref
        .read(appDatabaseProvider)
        .writeSetting(
          PrinterSettings.settingKey,
          jsonEncode(settings.toJson()),
        );
  }
}

final printerSettingsProvider =
    AsyncNotifierProvider<PrinterSettingsController, PrinterSettings>(
      PrinterSettingsController.new,
    );

/// Windows printeri tanlovi faqat Windows'da (testlarda almashtiriladi).
final windowsPrintingProvider = Provider<bool>((ref) => Winspool.supported);

/// Tizimga o'rnatilgan printerlar (Windows).
final systemPrintersProvider = Provider<List<String>>(
  (ref) => ref.watch(windowsPrintingProvider) ? Winspool.printers() : const [],
);
