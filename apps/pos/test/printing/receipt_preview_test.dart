import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/app/locale.dart';
import 'package:pos_app/features/printing/escpos.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_preview.dart';
import 'package:pos_app/features/printing/receipt_sample.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocales.uzLatn);

  for (final width in PaperWidth.values) {
    testWidgets('preview ${width.chars} columns: every row fits the paper', (
      tester,
    ) async {
      final rows = ReceiptBuilder(
        l10n,
        width: width,
      ).build(sampleReceipt(l10n, at: DateTime.utc(2026, 10, 15, 15)));
      for (final screen in [320.0, 1024.0]) {
        tester.view.physicalSize = Size(screen, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: PosTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReceiptPreview(rows: rows, width: width),
              ),
            ),
          ),
        );
        // Hech bir qator kesilmaydi: matn o'z kengligiga sig'adi.
        final paragraphs = tester.renderObjectList<RenderParagraph>(
          find.descendant(
            of: find.byType(ReceiptPreview),
            matching: find.byType(RichText),
          ),
        );
        expect(paragraphs, isNotEmpty);
        for (final p in paragraphs) {
          final text = p.text.toPlainText();
          final painter = TextPainter(
            text: p.text,
            textDirection: TextDirection.ltr,
          )..layout();
          expect(
            painter.width,
            lessThanOrEqualTo(p.size.width + 0.5),
            reason: '${width.chars} @ $screen: "$text"',
          );
          painter.dispose();
        }
      }
    });
  }

  test('preview shows what CP866 will print', () {
    expect(EscPos.printable('қ', PrinterEncoding.cp866), 'к');
  });
}
