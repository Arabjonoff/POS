import 'package:flutter/material.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/shifts/shift_service.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// X/Z hisobot: savdolar, to'lov turlari, qaytarishlar, kassa puli,
/// qarz to'lovlari, naqd hisobi (Z — sanalgan va farq).
class ShiftReportView extends StatelessWidget {
  const ShiftReportView({required this.report, super.key});

  final ShiftReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final r = report;

    Widget section(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(bottom: PosSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: PosTypography.smallStrong.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: PosSpacing.xs),
          ...rows,
        ],
      ),
    );

    Widget row(String label, int tiyin, {bool strong = false, PosTone? tone}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style:
                      (strong ? PosTypography.bodyStrong : PosTypography.body)
                          .copyWith(color: p.text),
                ),
              ),
              PosMoneyText(
                amount: tiyin,
                currency: fmt.currency,
                size: strong ? PosMoneySize.medium : PosMoneySize.body,
                tone: tone,
              ),
            ],
          ),
        );

    final difference = r.difference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section('${l10n.reportSales} · ${l10n.reportChecks(r.salesCount)}', [
          row(l10n.reportSales, r.salesTotal, strong: true),
          row(l10n.reportCash, r.paymentsCash),
          row(l10n.reportCard, r.paymentsCard),
          row(l10n.reportDebt, r.paymentsDebt),
        ]),
        section(
          '${l10n.reportRefunds} · ${l10n.reportChecks(r.refundsCount)}',
          [
            row(l10n.reportCash, r.refundsCash),
            row(l10n.reportDebt, r.refundsDebt),
          ],
        ),
        section(l10n.reportCashMovements, [
          row(l10n.reportCashIn, r.cashIn),
          row(l10n.reportCashOut, r.cashOut),
        ]),
        section(l10n.reportDebtPayments, [
          row(l10n.reportCash, r.debtPaymentsCash),
          row(l10n.reportCard, r.debtPaymentsCard),
        ]),
        section(l10n.reportCashBalance, [
          row(l10n.reportOpeningCash, r.openingCash),
          row(l10n.reportExpectedCash, r.expectedCash, strong: true),
          if (r.countedCash != null)
            row(l10n.reportCountedCash, r.countedCash!),
          if (difference != null)
            row(
              difference == 0
                  ? l10n.reportNoDifference
                  : (difference > 0 ? l10n.reportSurplus : l10n.reportShortage),
              difference,
              strong: true,
              tone: difference == 0
                  ? PosTone.success
                  : (difference > 0 ? PosTone.warning : PosTone.danger),
            ),
        ]),
      ],
    );
  }
}
