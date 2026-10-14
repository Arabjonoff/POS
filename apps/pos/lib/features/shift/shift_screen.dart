import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/shifts/shift_service.dart';
import 'package:pos_app/features/common/money_input.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/shift/cash_movement_dialog.dart';
import 'package:pos_app/features/shift/shift_providers.dart';
import 'package:pos_app/features/shift/shift_report_view.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Smena: X hisobot va yopish (sanalgan naqd → farq → Z hisobot).
class ShiftScreen extends ConsumerStatefulWidget {
  const ShiftScreen({super.key});

  @override
  ConsumerState<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends ConsumerState<ShiftScreen> {
  /// Yopilgandan keyin — Z hisobot.
  ShiftReport? _closed;

  Future<void> _close(ShiftReport x) async {
    final counted = await showPosDialog<int>(
      context: context,
      builder: (context) => _CloseShiftDialog(expectedCash: x.expectedCash),
    );
    if (counted == null || !mounted) return;
    final user = ref.read(sessionProvider).user;
    final z = await ref
        .read(shiftServiceProvider)
        .close(
          shiftId: x.shift.id,
          closedBy: user?.id ?? x.shift.openedBy,
          countedCashTiyin: counted,
        );
    if (mounted) setState(() => _closed = z);
  }

  Future<void> _moveCash(CashMovementType type) async {
    final result = await showCashMovementDialog(context, type: type);
    if (result != null && mounted) showCashMovementDone(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final closed = _closed;
    if (closed != null) {
      return _ReportPage(
        title: l10n.shiftClosedTitle,
        subtitle: l10n.shiftZReport,
        report: closed,
        actions: [
          PosButton(
            label: l10n.shiftPrintReport,
            icon: Icons.print_outlined,
            variant: PosButtonVariant.secondary,
            // Chek printeri — T-044.
            onPressed: null,
          ),
          PosButton(
            label: l10n.shiftBackToPos,
            icon: Icons.point_of_sale,
            onPressed: () => context.go('/pos'),
          ),
        ],
      );
    }

    final shift = ref.watch(currentShiftProvider).value;
    if (shift == null) {
      return SectionPage(
        title: l10n.shiftTitle,
        child: PosEmptyState(
          icon: Icons.lock_clock_outlined,
          title: l10n.statusShiftClosed,
          action: PosButton(
            label: l10n.shiftBackToPos,
            onPressed: () => context.go('/pos'),
          ),
        ),
      );
    }
    final report = ref.watch(shiftReportProvider(shift.id)).value;
    if (report == null) {
      return SectionPage(
        title: l10n.shiftTitle,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return _ReportPage(
      title: l10n.shiftTitle,
      subtitle: l10n.shiftXReport,
      info: l10n.shiftOpenedInfo(
        context.fmt.dateTime(shift.openedAt),
        ref.watch(sessionProvider).user?.fullName ?? '',
      ),
      report: report,
      footer: _CashMovementsCard(shiftId: shift.id),
      actions: [
        PosButton(
          key: const ValueKey('shift-cash-in'),
          label: l10n.cashIn,
          icon: Icons.add_circle_outline,
          variant: PosButtonVariant.secondary,
          onPressed: () => unawaited(_moveCash(CashMovementType.cashIn)),
        ),
        PosButton(
          key: const ValueKey('shift-cash-out'),
          label: l10n.cashOut,
          icon: Icons.remove_circle_outline,
          variant: PosButtonVariant.secondary,
          onPressed: () => unawaited(_moveCash(CashMovementType.cashOut)),
        ),
        PosButton(
          label: l10n.shiftCloseAction,
          icon: Icons.lock_outline,
          variant: PosButtonVariant.danger,
          onPressed: () => unawaited(_close(report)),
        ),
      ],
    );
  }
}

class _ReportPage extends StatelessWidget {
  const _ReportPage({
    required this.title,
    required this.subtitle,
    required this.report,
    required this.actions,
    this.info,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String? info;
  final ShiftReport report;
  final List<Widget> actions;

  /// Hisobotdan keyingi qo'shimcha karta (kassa puli harakatlari).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    return SectionPage(
      title: title,
      // X → Z: yangi hisobot tepadan boshlanadi.
      child: ListView(
        key: ValueKey(subtitle),
        padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (info != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: PosSpacing.m),
                      child: Text(
                        info!,
                        style: PosTypography.body.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  PosCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          subtitle,
                          style: PosTypography.h3.copyWith(color: p.text),
                        ),
                        const SizedBox(height: PosSpacing.m),
                        ShiftReportView(report: report),
                      ],
                    ),
                  ),
                  const SizedBox(height: PosSpacing.l),
                  Wrap(
                    spacing: PosSpacing.s,
                    runSpacing: PosSpacing.s,
                    children: actions,
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: PosSpacing.l),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yopish: sanalgan naqd → farq darhol ko'rinadi → tasdiqlash.
class _CloseShiftDialog extends StatefulWidget {
  const _CloseShiftDialog({required this.expectedCash});

  final int expectedCash;

  @override
  State<_CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<_CloseShiftDialog> {
  int _counted = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final diff = _counted - widget.expectedCash;
    final tone = diff == 0
        ? PosTone.success
        : (diff > 0 ? PosTone.warning : PosTone.danger);
    final diffLabel = diff == 0
        ? l10n.reportNoDifference
        : (diff > 0 ? l10n.reportSurplus : l10n.reportShortage);

    return PosDialog(
      icon: Icons.payments_outlined,
      title: l10n.shiftCloseTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.reportExpectedCash,
                  style: PosTypography.body.copyWith(color: p.textSecondary),
                ),
              ),
              PosMoneyText(
                amount: widget.expectedCash,
                currency: fmt.currency,
              ),
            ],
          ),
          const SizedBox(height: PosSpacing.m),
          MoneyInput(
            valueTiyin: _counted,
            onChanged: (v) => setState(() => _counted = v),
            onSubmit: () => Navigator.of(context).pop(_counted),
          ),
          const SizedBox(height: PosSpacing.m),
          Row(
            children: [
              Expanded(
                child: Text(
                  diffLabel,
                  style: PosTypography.bodyStrong.copyWith(
                    color: p.tone(tone).text,
                  ),
                ),
              ),
              PosMoneyText(
                amount: diff,
                currency: fmt.currency,
                size: PosMoneySize.medium,
                tone: tone,
              ),
            ],
          ),
        ],
      ),
      actions: [
        PosButton(
          label: l10n.actionCancel,
          variant: PosButtonVariant.secondary,
          shortcut: 'Esc',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PosButton(
          label: l10n.shiftCloseConfirm,
          variant: PosButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(_counted),
        ),
      ],
    );
  }
}

/// Smenadagi kassa puli harakatlari: vaqt, sabab, summa (+ / −).
class _CashMovementsCard extends ConsumerWidget {
  const _CashMovementsCard({required this.shiftId});

  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final movements =
        ref.watch(cashMovementsProvider(shiftId)).value ??
        const <CashMovement>[];
    return PosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.cashMovementsTitle,
            style: PosTypography.h3.copyWith(color: p.text),
          ),
          const SizedBox(height: PosSpacing.s),
          if (movements.isEmpty)
            Text(
              l10n.cashNoMovements,
              style: PosTypography.body.copyWith(color: p.textSecondary),
            )
          else
            for (final m in movements)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      m.type == CashMovementType.cashIn.code
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      size: PosSizes.iconM,
                      color: p.textSecondary,
                    ),
                    const SizedBox(width: PosSpacing.s),
                    Expanded(
                      child: Text(
                        '${fmt.time(m.at)} · ${m.reason}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PosTypography.body.copyWith(color: p.text),
                      ),
                    ),
                    PosMoneyText(
                      amount: m.type == CashMovementType.cashIn.code
                          ? m.amountTiyin
                          : -m.amountTiyin,
                      currency: fmt.currency,
                      tone: m.type == CashMovementType.cashIn.code
                          ? PosTone.success
                          : PosTone.danger,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
