import 'package:flutter/widgets.dart';
import 'package:pos_app/data/receipts/receipt_store.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Kirim holati belgilari (ro'yxat va karta bir xil): holat + "Tuzatish"
/// (boshqa kirimning yangi versiyasi bo'lsa).
class ReceiptBadges extends StatelessWidget {
  const ReceiptBadges({
    required this.state,
    required this.isCorrection,
    super.key,
  });

  final ReceiptState state;
  final bool isCorrection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone) = switch (state) {
      ReceiptState.draft => (
        isCorrection ? l10n.receivingCorrectionDraft : l10n.receivingDraft,
        PosTone.warning,
      ),
      ReceiptState.posted => (l10n.receivingPostedBadge, PosTone.success),
      ReceiptState.corrected => (l10n.receivingStateCorrected, PosTone.neutral),
      ReceiptState.cancelled => (l10n.receivingStateCancelled, PosTone.danger),
    };
    return Wrap(
      spacing: PosSpacing.xs,
      runSpacing: PosSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        if (isCorrection && state != ReceiptState.draft)
          PosBadge(label: l10n.receivingCorrectionBadge, tone: PosTone.primary),
        PosBadge(label: label, tone: tone),
      ],
    );
  }
}

/// [ReceiptDoc] dan ro'yxatdagi holat.
ReceiptState receiptStateOf(ReceiptDoc doc) {
  if (doc.isDraft) return ReceiptState.draft;
  if (doc.isCorrected) return ReceiptState.corrected;
  if (doc.cancelled) return ReceiptState.cancelled;
  return ReceiptState.posted;
}
