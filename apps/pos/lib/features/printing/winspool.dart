// FFI: C va Dart imzolari juft typedef sifatida — o'qilishi uchun.
// ignore_for_file: avoid_private_typedef_functions

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Windows chop etish navbati (`winspool.drv`) — faqat kerakli 8 funksiya.
/// ESC/POS baytlari "RAW" turida, drayver ularni o'zgartirmasdan printerga
/// uzatadi (`printing.md`: tizimga o'rnatilgan printer).
abstract final class Winspool {
  static final DynamicLibrary _lib = DynamicLibrary.open('winspool.drv');

  static final _OpenPrinter _openPrinter = _lib
      .lookupFunction<_OpenPrinterC, _OpenPrinter>('OpenPrinterW');
  static final _StartDoc _startDocPrinter = _lib
      .lookupFunction<_StartDocC, _StartDoc>('StartDocPrinterW');
  static final _HandleFn _startPagePrinter = _lib
      .lookupFunction<_HandleFnC, _HandleFn>('StartPagePrinter');
  static final _Write _writePrinter = _lib.lookupFunction<_WriteC, _Write>(
    'WritePrinter',
  );
  static final _HandleFn _endPagePrinter = _lib
      .lookupFunction<_HandleFnC, _HandleFn>('EndPagePrinter');
  static final _HandleFn _endDocPrinter = _lib
      .lookupFunction<_HandleFnC, _HandleFn>('EndDocPrinter');
  static final _HandleFn _closePrinter = _lib
      .lookupFunction<_HandleFnC, _HandleFn>('ClosePrinter');
  static final _EnumPrinters _enumPrinters = _lib
      .lookupFunction<_EnumPrintersC, _EnumPrinters>('EnumPrintersW');

  static const int _printerEnumLocal = 0x2;
  static const int _printerEnumConnections = 0x4;

  static bool get supported => Platform.isWindows;

  /// O'rnatilgan printerlar nomlari (lokal + tarmoq ulanishlari).
  static List<String> printers() {
    if (!supported) return const [];
    return using((arena) {
      const flags = _printerEnumLocal | _printerEnumConnections;
      final needed = arena<Uint32>();
      final returned = arena<Uint32>();
      _enumPrinters(flags, nullptr, 4, nullptr, 0, needed, returned);
      if (needed.value == 0) return const <String>[];
      final buffer = arena<Uint8>(needed.value);
      final ok = _enumPrinters(
        flags,
        nullptr,
        4,
        buffer,
        needed.value,
        needed,
        returned,
      );
      if (ok == 0) return const <String>[];
      final infos = buffer.cast<_PrinterInfo4>();
      return [
        for (var i = 0; i < returned.value; i++)
          infos[i].pPrinterName.toDartString(),
      ];
    });
  }

  /// [bytes] ni [printer] ga RAW hujjat sifatida yuboradi. Xato —
  /// [WinspoolException].
  static void writeRaw(String printer, Uint8List bytes, {String doc = 'POS'}) {
    if (!supported) throw const WinspoolException('not_windows');
    using((arena) {
      final handle = arena<IntPtr>();
      if (_openPrinter(
            printer.toNativeUtf16(allocator: arena),
            handle,
            nullptr,
          ) ==
          0) {
        throw const WinspoolException('open');
      }
      final h = handle.value;
      try {
        final info = arena<_DocInfo1>()
          ..ref.pDocName = doc.toNativeUtf16(allocator: arena)
          ..ref.pOutputFile = nullptr
          ..ref.pDatatype = 'RAW'.toNativeUtf16(allocator: arena);
        if (_startDocPrinter(h, 1, info) == 0) {
          throw const WinspoolException('start_doc');
        }
        try {
          if (_startPagePrinter(h) == 0) {
            throw const WinspoolException('start_page');
          }
          final data = arena<Uint8>(bytes.length)
            ..asTypedList(bytes.length).setAll(0, bytes);
          final written = arena<Uint32>();
          final ok = _writePrinter(h, data, bytes.length, written);
          _endPagePrinter(h);
          if (ok == 0 || written.value != bytes.length) {
            throw const WinspoolException('write');
          }
        } finally {
          _endDocPrinter(h);
        }
      } finally {
        _closePrinter(h);
      }
    });
  }
}

typedef _OpenPrinterC =
    Int32 Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>);
typedef _OpenPrinter =
    int Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>);
typedef _StartDocC = Uint32 Function(IntPtr, Uint32, Pointer<_DocInfo1>);
typedef _StartDoc = int Function(int, int, Pointer<_DocInfo1>);
typedef _HandleFnC = Int32 Function(IntPtr);
typedef _HandleFn = int Function(int);
typedef _WriteC =
    Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>);
typedef _Write = int Function(int, Pointer<Uint8>, int, Pointer<Uint32>);
typedef _EnumPrintersC =
    Int32 Function(
      Uint32,
      Pointer<Utf16>,
      Uint32,
      Pointer<Uint8>,
      Uint32,
      Pointer<Uint32>,
      Pointer<Uint32>,
    );
typedef _EnumPrinters =
    int Function(
      int,
      Pointer<Utf16>,
      int,
      Pointer<Uint8>,
      int,
      Pointer<Uint32>,
      Pointer<Uint32>,
    );

class WinspoolException implements Exception {
  const WinspoolException(this.step);

  final String step;

  @override
  String toString() => 'WinspoolException($step)';
}

final class _DocInfo1 extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

final class _PrinterInfo4 extends Struct {
  external Pointer<Utf16> pPrinterName;
  external Pointer<Utf16> pServerName;

  @Uint32()
  external int attributes;
}
