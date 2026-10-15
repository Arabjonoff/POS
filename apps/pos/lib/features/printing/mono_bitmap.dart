import 'dart:io' show ZLibCodec;
import 'dart:math' as math;
import 'dart:typed_data';

/// Kulrang rasm (0 — qora, 255 — oq), qator bo'yicha.
class GrayImage {
  GrayImage(this.width, this.height, this.pixels)
    : assert(pixels.length == width * height, 'pixels');

  /// RGBA dan (shaffof joy — oq qog'oz ustida).
  factory GrayImage.fromRgba(int width, int height, Uint8List rgba) {
    final out = Uint8List(width * height);
    for (var i = 0; i < out.length; i++) {
      final r = rgba[i * 4];
      final g = rgba[i * 4 + 1];
      final b = rgba[i * 4 + 2];
      final a = rgba[i * 4 + 3];
      final lum = (299 * r + 587 * g + 114 * b) ~/ 1000;
      out[i] = (lum * a + 255 * (255 - a)) ~/ 255;
    }
    return GrayImage(width, height, out);
  }

  final int width;
  final int height;
  final Uint8List pixels;

  /// Nisbatni saqlab [maxWidth] × [maxHeight] ga sig'diradi (kichraytirish —
  /// o'rtacha qiymat bilan; kattalashtirilmaydi).
  GrayImage fit(int maxWidth, int maxHeight) {
    final scale = math.min(
      1,
      math.min(maxWidth / width, maxHeight / height),
    );
    if (scale >= 1) return this;
    final w = math.max(1, (width * scale).round());
    final h = math.max(1, (height * scale).round());
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final y0 = y * height ~/ h;
      final y1 = math.max(y0 + 1, (y + 1) * height ~/ h);
      for (var x = 0; x < w; x++) {
        final x0 = x * width ~/ w;
        final x1 = math.max(x0 + 1, (x + 1) * width ~/ w);
        var sum = 0;
        for (var yy = y0; yy < y1; yy++) {
          for (var xx = x0; xx < x1; xx++) {
            sum += pixels[yy * width + xx];
          }
        }
        out[y * w + x] = sum ~/ ((y1 - y0) * (x1 - x0));
      }
    }
    return GrayImage(w, h, out);
  }

  /// Kulrang PNG (8 bit, filtrsiz) — serverga va bazaga shu ko'rinishda.
  Uint8List toPng() {
    final raw = BytesBuilder(copy: false);
    for (var y = 0; y < height; y++) {
      raw
        ..addByte(0) // filtr: yo'q
        ..add(Uint8List.sublistView(pixels, y * width, (y + 1) * width));
    }
    final header = ByteData(13)
      ..setUint32(0, width)
      ..setUint32(4, height)
      ..setUint8(8, 8) // bit chuqurligi
      ..setUint8(9, 0) // rang turi: kulrang
      ..setUint8(10, 0)
      ..setUint8(11, 0)
      ..setUint8(12, 0);
    final out = BytesBuilder(copy: false)..add(_pngSignature);
    _chunk(out, 'IHDR', header.buffer.asUint8List());
    _chunk(
      out,
      'IDAT',
      Uint8List.fromList(ZLibCodec().encode(raw.takeBytes())),
    );
    _chunk(out, 'IEND', Uint8List(0));
    return out.takeBytes();
  }

  /// [toPng] chiqargan (yoki shunga o'xshash: 8 bitli kulrang, interlace'siz)
  /// PNG ni o'qiydi; boshqa format — `null`.
  static GrayImage? fromPng(Uint8List bytes) {
    if (bytes.length < 8 || !_startsWith(bytes, _pngSignature)) return null;
    final data = ByteData.sublistView(bytes);
    var pos = 8;
    int? width;
    int? height;
    final idat = BytesBuilder(copy: false);
    while (pos + 8 <= bytes.length) {
      final length = data.getUint32(pos);
      final type = String.fromCharCodes(bytes.sublist(pos + 4, pos + 8));
      final body = Uint8List.sublistView(bytes, pos + 8, pos + 8 + length);
      if (type == 'IHDR') {
        width = data.getUint32(pos + 8);
        height = data.getUint32(pos + 12);
        final bitDepth = body[8];
        final colorType = body[9];
        final interlace = body[12];
        if (bitDepth != 8 || colorType != 0 || interlace != 0) return null;
      } else if (type == 'IDAT') {
        idat.add(body);
      } else if (type == 'IEND') {
        break;
      }
      pos += 12 + length;
    }
    if (width == null || height == null) return null;
    final raw = Uint8List.fromList(ZLibCodec().decode(idat.takeBytes()));
    if (raw.length < height * (width + 1)) return null;
    final out = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      final filter = raw[y * (width + 1)];
      for (var x = 0; x < width; x++) {
        final value = raw[y * (width + 1) + 1 + x];
        final left = x > 0 ? out[y * width + x - 1] : 0;
        final up = y > 0 ? out[(y - 1) * width + x] : 0;
        final upLeft = x > 0 && y > 0 ? out[(y - 1) * width + x - 1] : 0;
        out[y * width + x] =
            switch (filter) {
              1 => value + left,
              2 => value + up,
              3 => value + ((left + up) >> 1),
              4 => value + _paeth(left, up, upLeft),
              _ => value,
            } &
            0xff;
      }
    }
    return GrayImage(width, height, out);
  }

  static int _paeth(int a, int b, int c) {
    final p = a + b - c;
    final pa = (p - a).abs();
    final pb = (p - b).abs();
    final pc = (p - c).abs();
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
  }

  static const List<int> _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }

  static void _chunk(BytesBuilder out, String type, Uint8List body) {
    final typeBytes = Uint8List.fromList(type.codeUnits);
    out
      ..add((ByteData(4)..setUint32(0, body.length)).buffer.asUint8List())
      ..add(typeBytes)
      ..add(body)
      ..add(
        (ByteData(
          4,
        )..setUint32(0, _crc32([...typeBytes, ...body]))).buffer.asUint8List(),
      );
  }

  static final List<int> _crcTable = List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xedb88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });

  static int _crc32(List<int> bytes) {
    var c = 0xffffffff;
    for (final b in bytes) {
      c = _crcTable[(c ^ b) & 0xff] ^ (c >> 8);
    }
    return c ^ 0xffffffff;
  }
}

/// 1 bitli rasm (printer uchun): 1 — qora nuqta. Qator [bytesPerRow] bayt,
/// chapdan o'ngga, katta bit birinchi (ESC/POS `GS v 0`).
class MonoBitmap {
  MonoBitmap(this.width, this.height, this.bits);

  /// Kulrang rasmdan: kenglik [maxDots] dan oshmaydi (58 mm — 384, 80 mm —
  /// 576 nuqta), [threshold] dan qora — nuqta.
  factory MonoBitmap.fromGray(
    GrayImage image, {
    required int maxDots,
    int threshold = 128,
  }) {
    // Faqat kenglik cheklanadi (balandlik logotipni saqlashda cheklangan).
    final fitted = image.fit(maxDots, image.height);
    final bytesPerRow = (fitted.width + 7) ~/ 8;
    final bits = Uint8List(bytesPerRow * fitted.height);
    for (var y = 0; y < fitted.height; y++) {
      for (var x = 0; x < fitted.width; x++) {
        if (fitted.pixels[y * fitted.width + x] < threshold) {
          bits[y * bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
        }
      }
    }
    return MonoBitmap(fitted.width, fitted.height, bits);
  }

  final int width;
  final int height;
  final Uint8List bits;

  int get bytesPerRow => (width + 7) ~/ 8;

  bool isBlack(int x, int y) =>
      bits[y * bytesPerRow + (x >> 3)] & (0x80 >> (x & 7)) != 0;
}
