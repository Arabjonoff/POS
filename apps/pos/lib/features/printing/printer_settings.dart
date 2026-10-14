import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/receipt.dart';

/// Printer ulanishi. Android Bluetooth/USB — keyinroq (qaror 0008).
enum PrinterConnection {
  none('none'),
  network('network'),
  windows('windows')
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
    this.width = PaperWidth.mm58,
    this.encoding = PrinterEncoding.cp866,
    this.autoPrint = true,
    this.copies = 1,
    this.openDrawer = false,
  });

  factory PrinterSettings.fromJson(Map<String, Object?> json) =>
      PrinterSettings(
        connection: PrinterConnection.fromCode(json['connection'] as String?),
        address: json['address'] as String? ?? '',
        width: json['width'] == 80 ? PaperWidth.mm80 : PaperWidth.mm58,
        encoding: PrinterEncoding.fromCode(json['encoding'] as String?),
        autoPrint: json['auto_print'] as bool? ?? true,
        copies: ((json['copies'] as int?) ?? 1).clamp(1, maxCopies),
        openDrawer: json['open_drawer'] as bool? ?? false,
      );

  static const String settingKey = 'printer';
  static const int maxCopies = 3;

  final PrinterConnection connection;

  /// Tarmoq — `IP[:port]`; Windows — printer nomi.
  final String address;
  final PaperWidth width;
  final PrinterEncoding encoding;

  /// Savdo yakunlanganda chek avtomatik chiqadi.
  final bool autoPrint;
  final int copies;

  /// Naqd to'lovda pul qutisini ochish.
  final bool openDrawer;

  bool get configured =>
      connection != PrinterConnection.none && address.trim().isNotEmpty;

  Map<String, Object?> toJson() => {
    'connection': connection.code,
    'address': address,
    'width': width == PaperWidth.mm80 ? 80 : 58,
    'encoding': encoding.code,
    'auto_print': autoPrint,
    'copies': copies,
    'open_drawer': openDrawer,
  };

  PrinterSettings copyWith({
    PrinterConnection? connection,
    String? address,
    PaperWidth? width,
    PrinterEncoding? encoding,
    bool? autoPrint,
    int? copies,
    bool? openDrawer,
  }) => PrinterSettings(
    connection: connection ?? this.connection,
    address: address ?? this.address,
    width: width ?? this.width,
    encoding: encoding ?? this.encoding,
    autoPrint: autoPrint ?? this.autoPrint,
    copies: (copies ?? this.copies).clamp(1, maxCopies),
    openDrawer: openDrawer ?? this.openDrawer,
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
