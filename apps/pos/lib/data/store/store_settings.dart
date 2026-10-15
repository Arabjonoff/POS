import 'dart:convert';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/text/clean_text.dart';
import 'package:pos_app/core/text/phone.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/ids.dart';
import 'package:pos_app/data/sync/outbox.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/receipt.dart';

/// Chek rekvizitlari (do'kon sozlamasi, T-104b) — bitta do'kon, hamma
/// kassada bir xil; server — `store.upserted`.
class StoreDraft {
  const StoreDraft({
    required this.id,
    required this.name,
    this.legalName = '',
    this.tin = '',
    this.address = '',
    this.phone = '',
    this.header = '',
    this.footer = '',
    this.logo,
    this.options = const ReceiptOptions(),
  });

  factory StoreDraft.fromRow(Store row, {GrayImage? logo}) => StoreDraft(
    id: row.id,
    name: row.name,
    legalName: row.legalName,
    tin: row.tin,
    address: row.address,
    phone: row.phone,
    header: row.receiptHeader,
    footer: row.receiptFooter,
    logo: logo,
    options: _options(row.receiptOptions),
  );

  final String id;
  final String name;
  final String legalName;
  final String tin;
  final String address;
  final String phone;
  final String header;
  final String footer;
  final GrayImage? logo;
  final ReceiptOptions options;

  static ReceiptOptions _options(String json) {
    try {
      final value = jsonDecode(json);
      return value is Map<String, Object?>
          ? ReceiptOptions.fromJson(value)
          : const ReceiptOptions();
    } on FormatException {
      return const ReceiptOptions();
    }
  }
}

/// Tekshiruv xatosi (maydon bo'yicha).
enum StoreProblem { nameRequired, tinFormat, phoneFormat, logoTooLarge }

/// Logotip baytlari chegarasi (server bilan bir xil: 96 KB).
const int maxLogoBytes = 96 * 1024;

/// Logotip o'lchami: 80 mm printer kengligi va ~30 mm balandlik.
const int maxLogoWidth = 576;
const int maxLogoHeight = 240;

class StoreSettingsStore {
  StoreSettingsStore(this._db, {IdGenerator? newId, DateTime Function()? now})
    : _newId = newId ?? _defaultId,
      _now = now ?? _clockNow;

  static String _defaultId() => newId();
  static DateTime _clockNow() => clock.now();

  final AppDatabase _db;
  final IdGenerator _newId;
  final DateTime Function() _now;

  Stream<Store?> watch() => _db.select(_db.stores).watchSingleOrNull();

  static List<StoreProblem> validate(StoreDraft d) => [
    if (cleanLine(d.name).isEmpty) StoreProblem.nameRequired,
    if (d.tin.trim().isNotEmpty &&
        !RegExp(r'^(\d{9}|\d{14})$').hasMatch(d.tin.trim()))
      StoreProblem.tinFormat,
    if (normalizePhone(d.phone) == null) StoreProblem.phoneFormat,
    if (d.logo != null && d.logo!.toPng().length > maxLogoBytes)
      StoreProblem.logoTooLarge,
  ];

  /// Lokal `stores` qatori va `store.upserted` — bitta tranzaksiyada
  /// (oflayn ham ishlaydi). [by] — ega yoki menejer.
  Future<void> save(StoreDraft d, {required String by}) async {
    final problems = validate(d);
    if (problems.isNotEmpty) throw ArgumentError(problems.join(','));
    final logo = d.logo == null ? '' : base64Encode(d.logo!.toPng());
    final options = jsonEncode(d.options.toJson());
    final phone = normalizePhone(d.phone)!;
    final now = _now();
    await _db.transaction(() async {
      await (_db.update(_db.stores)..where((s) => s.id.equals(d.id))).write(
        StoresCompanion(
          name: Value(cleanLine(d.name)),
          legalName: Value(cleanLine(d.legalName)),
          tin: Value(d.tin.trim()),
          address: Value(cleanLine(d.address)),
          phone: Value(phone),
          receiptHeader: Value(d.header.trim()),
          receiptFooter: Value(d.footer.trim()),
          receiptLogo: Value(logo),
          receiptOptions: Value(options),
        ),
      );
      await _db.enqueueEvent(
        id: _newId(),
        type: OutboxEventType.storeUpserted,
        createdAt: now,
        payload: {
          'id': d.id,
          'name': cleanLine(d.name),
          'legal_name': cleanLine(d.legalName),
          'tin': d.tin.trim(),
          'address': cleanLine(d.address),
          'phone': phone,
          'receipt_header': d.header.trim(),
          'receipt_footer': d.footer.trim(),
          'receipt_logo': logo,
          'receipt_options': d.options.toJson(),
          'by': by,
        },
      );
    });
  }
}

final storeSettingsProvider = Provider<StoreSettingsStore>(
  (ref) => StoreSettingsStore(ref.watch(appDatabaseProvider)),
);

/// Logotip tanlash: rasm fayli → kulrang, chek kengligiga kichraytirilgan
/// (testlarda almashtiriladi). `null` — bekor qilindi; o'qib bo'lmasa —
/// [FormatException].
typedef LogoPicker = Future<GrayImage?> Function();

Future<GrayImage?> _pickPlatformLogo() async {
  final files = await FilePicker.pickFiles(type: FileType.image);
  if (files.isEmpty) return null;
  return decodeLogo(await files.first.readAsBytes());
}

/// Har qanday rasm (PNG, JPG...) → kulrang, ≤ 576 × 240.
Future<GrayImage> decodeLogo(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final rgba = await image.toByteData();
    final gray = GrayImage.fromRgba(
      image.width,
      image.height,
      rgba!.buffer.asUint8List(),
    );
    image.dispose();
    codec.dispose();
    return gray.fit(maxLogoWidth, maxLogoHeight);
  } on Exception catch (e) {
    throw FormatException('logo: $e');
  }
}

final logoPickerProvider = Provider<LogoPicker>((ref) => _pickPlatformLogo);
