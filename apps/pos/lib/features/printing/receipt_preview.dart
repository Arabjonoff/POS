import 'package:flutter/material.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_ui/pos_ui.dart';

/// Chek ko'rinishi (preview): printerga yuboriladigan **o'sha** qatorlar
/// ([ReceiptRow]) — ustunlar, o'ralish, qalin/baland qatorlar va kodlash
/// jadvalida yo'q harflar (`?`) qog'ozdagidek. Qog'oz doim oq.
class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({
    required this.rows,
    required this.width,
    this.encoding = PrinterEncoding.cp866,
    super.key,
  });

  final List<ReceiptRow> rows;
  final PaperWidth width;
  final PrinterEncoding encoding;

  /// Ekrandagi qog'oz kengligi: 58 mm — torroq, 80 mm — kengroq.
  double get _paperWidth => width.mm == 58 ? 300 : 400;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _paperWidth),
        child: DecoratedBox(
          key: const ValueKey('receipt-preview'),
          decoration: BoxDecoration(
            color: PosColors.receiptPaper,
            borderRadius: PosRadius.controlAll,
            border: Border.all(color: p.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PosSpacing.m,
              vertical: PosSpacing.l,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final style = _fit(constraints.maxWidth);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final row in rows) _row(row, style),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Shrift o'lchami: [PaperWidth.chars] ta belgi qog'oz kengligiga sig'adi.
  TextStyle _fit(double available) {
    const base = PosTypography.receipt;
    final painter = TextPainter(
      text: TextSpan(text: '0' * width.chars, style: base),
      textDirection: TextDirection.ltr,
    )..layout();
    // 2% zaxira: kenglik yaxlitlanishi oxirgi belgini kesmasin.
    final scale = available * 0.98 / painter.width;
    painter.dispose();
    return base.copyWith(
      fontSize: (base.fontSize! * scale).clamp(6, 18),
      color: PosColors.receiptInk,
    );
  }

  Widget _row(ReceiptRow row, TextStyle style) {
    final image = row.image;
    if (image != null) {
      return _Logo(image: image, dots: width.mm == 58 ? 384 : 576);
    }
    if (row.barcode) return _Barcode(text: row.text, style: style);
    final text = Text(
      EscPos.printable(row.text, encoding),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      textAlign: row.center ? TextAlign.center : TextAlign.left,
      style: style.copyWith(
        fontWeight: row.bold ? FontWeight.w700 : FontWeight.w400,
      ),
    );
    if (!row.tall) return text;
    // Baland qator (JAMI): printerdagi `GS !` — ikki barobar balandlik.
    final lineHeight = style.fontSize! * style.height!;
    return SizedBox(
      height: lineHeight * 2,
      child: Transform.scale(
        scaleY: 2,
        alignment: Alignment.topCenter,
        child: text,
      ),
    );
  }
}

/// Logotip: printerga yuboriladigan 1 bitli nuqtalar (qog'oz kengligiga
/// nisbatan o'sha o'lchamda).
class _Logo extends StatelessWidget {
  const _Logo({required this.image, required this.dots});

  final MonoBitmap image;
  final int dots;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PosSpacing.xs),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / dots;
        return Center(
          child: SizedBox(
            width: image.width * scale,
            height: image.height * scale,
            child: CustomPaint(painter: _LogoPainter(image)),
          ),
        );
      },
    ),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.image);

  final MonoBitmap image;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = size.width / image.width;
    final paint = Paint()..color = PosColors.receiptInk;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (image.isBlack(x, y)) {
          canvas.drawRect(Rect.fromLTWH(x * dot, y * dot, dot, dot), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => !identical(old.image, image);
}

/// Chek raqami shtrix-kodi (ko'rinish uchun chiziqlar; printer CODE128
/// chiqaradi) va ostida raqam.
class _Barcode extends StatelessWidget {
  const _Barcode({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
    child: Column(
      children: [
        SizedBox(
          height: style.fontSize! * 3,
          width: double.infinity,
          child: CustomPaint(painter: _BarsPainter(text)),
        ),
        Text(text, style: style),
      ],
    ),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.text);

  final String text;

  @override
  void paint(Canvas canvas, Size size) {
    // Har belgi — 11 modul (CODE128 kabi), boshida va oxirida to'xtash.
    final bits = <bool>[true, true, false, true];
    for (final unit in text.codeUnits) {
      for (var i = 10; i >= 0; i--) {
        bits.add(((unit * 37 + 11) >> (i % 8)).isOdd || i == 10);
      }
    }
    bits.addAll([true, true, false, true, true]);
    final module = (size.width * 0.8) / bits.length;
    final left = (size.width - module * bits.length) / 2;
    final paint = Paint()..color = PosColors.receiptInk;
    for (var i = 0; i < bits.length; i++) {
      if (bits[i]) {
        canvas.drawRect(
          Rect.fromLTWH(left + i * module, 0, module, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.text != text;
}
