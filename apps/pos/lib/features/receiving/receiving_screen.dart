import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/receipts/receipt_store.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/receiving/receipt_editor.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

final receiptsProvider = StreamProvider<List<ReceiptSummary>>(
  (ref) => ref.watch(receiptStoreProvider).watchAll(),
);

/// Bo'lim "Kirim" (Ctrl+3): kirimlar ro'yxati (qoralamalar birinchi) va
/// tahrirlovchi (`stock-receipt.md`).
class ReceivingScreen extends ConsumerStatefulWidget {
  const ReceivingScreen({super.key});

  @override
  ConsumerState<ReceivingScreen> createState() => _ReceivingScreenState();
}

class _ReceivingScreenState extends ConsumerState<ReceivingScreen> {
  String? _openId;

  Future<void> _new() async {
    final id = await ref.read(receiptStoreProvider).create();
    if (mounted) setState(() => _openId = id);
  }

  @override
  Widget build(BuildContext context) {
    final openId = _openId;
    if (openId != null) {
      return ReceiptEditor(
        key: ValueKey(openId),
        receiptId: openId,
        onClose: () => setState(() => _openId = null),
      );
    }
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final receipts = ref.watch(receiptsProvider).value;
    final newButton = PosButton(
      key: const ValueKey('receiving-new'),
      label: l10n.receivingNew,
      icon: Icons.add,
      onPressed: () => unawaited(_new()),
    );

    final Widget body;
    if (receipts == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (receipts.isEmpty) {
      body = PosEmptyState(
        icon: Icons.move_to_inbox_outlined,
        title: l10n.receivingEmptyTitle,
        message: l10n.receivingEmptyMessage,
        action: newButton,
      );
    } else {
      body = ListView.separated(
        padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
        itemCount: receipts.length,
        separatorBuilder: (_, _) => const SizedBox(height: PosSpacing.s),
        itemBuilder: (context, i) {
          final r = receipts[i];
          return PosCard(
            key: ValueKey('receipt-${r.id}'),
            onTap: () => setState(() => _openId = r.id),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fmt.dateTime(r.postedAt ?? r.createdAt),
                        style: PosTypography.bodyStrong.copyWith(color: p.text),
                      ),
                      Text(
                        [
                          ?r.supplierName,
                          l10n.receivingLines(r.lineCount),
                        ].join(' · '),
                        style: PosTypography.small.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PosSpacing.s),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PosMoneyText(
                      amount: r.totalCostTiyin,
                      currency: fmt.currency,
                    ),
                    const SizedBox(height: PosSpacing.xs),
                    PosBadge(
                      label: r.isDraft
                          ? l10n.receivingDraft
                          : l10n.receivingPostedBadge,
                      tone: r.isDraft ? PosTone.warning : PosTone.success,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return SectionPage(
      title: l10n.navReceiving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (receipts != null && receipts.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, PosSpacing.m),
              child: Align(alignment: Alignment.centerLeft, child: newButton),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
