import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/receipt_preview.dart';
import 'package:pos_app/features/printing/receipt_sample.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Sozlamalar → Chek ko'rinishi: joriy kenglik va kodlash jadvali bilan
/// oxirgi savdo cheki (yoki namuna) — printer aynan shunday chiqaradi.
class ReceiptPreviewPanel extends ConsumerWidget {
  const ReceiptPreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(printerSettingsProvider).value ?? const PrinterSettings();
    final preview = ref.watch(receiptPreviewDataProvider).value;
    if (preview == null) {
      return const Padding(
        padding: EdgeInsets.all(PosSpacing.l),
        child: PosSkeleton(height: 320),
      );
    }
    final rows = ref.watch(printerServiceProvider).previewRows(preview.data);
    return Padding(
      padding: const EdgeInsets.all(PosSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PosBadge(
              label: preview.isSample
                  ? l10n.receiptPreviewSample
                  : l10n.receiptPreviewLast,
            ),
          ),
          const SizedBox(height: PosSpacing.m),
          ReceiptPreview(
            rows: rows,
            width: settings.width,
            encoding: settings.encoding,
          ),
        ],
      ),
    );
  }
}
