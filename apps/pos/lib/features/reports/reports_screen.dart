import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/core/money/money.dart';
import 'package:pos_app/core/time/store_time_zone.dart';
import 'package:pos_app/data/reports/reports.dart';
import 'package:pos_app/data/reports/reports_provider.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Tez tanlanadigan davrlar (`reports.md`).
enum ReportPreset {
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth
  ;

  /// [day] — do'kon bo'yicha bugungi kun (devor soati).
  ReportPeriod period(DateTime day) => switch (this) {
    today => ReportPeriod(day, day),
    yesterday => ReportPeriod(
      day.subtract(const Duration(days: 1)),
      day.subtract(const Duration(days: 1)),
    ),
    last7Days => ReportPeriod(day.subtract(const Duration(days: 6)), day),
    thisMonth => ReportPeriod(DateTime.utc(day.year, day.month), day),
    lastMonth => ReportPeriod(
      DateTime.utc(day.year, day.month - 1),
      DateTime.utc(day.year, day.month, 0),
    ),
  };

  String label(AppLocalizations l10n) => switch (this) {
    today => l10n.reportsToday,
    yesterday => l10n.reportsYesterday,
    last7Days => l10n.reportsLast7Days,
    thisMonth => l10n.reportsThisMonth,
    lastMonth => l10n.reportsLastMonth,
  };
}

/// Bo'lim "Hisobotlar" (Ctrl+5): ega va menejer uchun. Onlayn — barcha
/// kassalar (server), oflayn — faqat shu kassa (lokal baza).
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPreset _preset = ReportPreset.today;

  /// Kassir uchun menejer PIN bilan ochilgan (shu kassir sessiyasida).
  String? _unlockedFor;

  Future<void> _unlock(String userId) async {
    final l10n = AppLocalizations.of(context);
    final by = await requestManagerApproval(
      context,
      reason: l10n.reportsUnlockReason,
    );
    if (by != null && mounted) setState(() => _unlockedFor = userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final allowed =
        user != null &&
        (DiscountPolicy.canApprove(user.role) || _unlockedFor == user.id);
    if (!allowed) {
      return SectionPage(
        title: l10n.navReports,
        child: PosEmptyState(
          icon: Icons.lock_outline,
          title: l10n.reportsNoAccessTitle,
          message: l10n.reportsNoAccessMessage,
          action: user == null
              ? null
              : PosButton(
                  key: const ValueKey('reports-unlock'),
                  label: l10n.reportsUnlock,
                  icon: Icons.pin_outlined,
                  onPressed: () => unawaited(_unlock(user.id)),
                ),
        ),
      );
    }

    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final today = StoreTimeZone.tashkent.today(ref.watch(clockProvider)());
    final period = _preset.period(today);
    final reports = ref.watch(reportsProvider(period));

    return SectionPage(
      title: l10n.navReports,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, PosSpacing.m),
            child: _PeriodBar(
              selected: _preset,
              period: period,
              local: reports.value?.local ?? false,
              onSelected: (preset) => setState(() => _preset = preset),
            ),
          ),
          Expanded(
            child: switch (reports) {
              AsyncData(:final value) => _ReportsView(
                reports: value,
                padding: padding,
              ),
              AsyncError() => PosEmptyState(
                icon: Icons.error_outline,
                tone: PosTone.danger,
                title: l10n.reportsLoadFailed,
                action: PosButton(
                  label: l10n.actionRetry,
                  onPressed: () => ref.invalidate(reportsProvider(period)),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.selected,
    required this.period,
    required this.local,
    required this.onSelected,
  });

  final ReportPreset selected;
  final ReportPeriod period;
  final bool local;
  final ValueChanged<ReportPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final from = _date(period.from);
    final to = _date(period.to);
    return Wrap(
      spacing: PosSpacing.s,
      runSpacing: PosSpacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final preset in ReportPreset.values)
          PosButton(
            key: ValueKey('reports-period-${preset.name}'),
            label: preset.label(l10n),
            size: PosButtonSize.s,
            variant: preset == selected
                ? PosButtonVariant.primary
                : PosButtonVariant.secondary,
            onPressed: () => onSelected(preset),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PosSpacing.s),
          child: Text(
            from == to ? from : l10n.reportsPeriodRange(from, to),
            key: const ValueKey('reports-period-range'),
            style: PosTypography.small.copyWith(color: p.textSecondary),
          ),
        ),
        if (local)
          PosBadge(
            key: const ValueKey('reports-local'),
            label: l10n.reportsLocalOnly,
            icon: Icons.cloud_off_outlined,
            tone: PosTone.warning,
          ),
      ],
    );
  }
}

/// Do'kon kuni (devor soati) `15.10.2026`.
String _date(DateTime day) => '${_two(day.day)}.${_two(day.month)}.${day.year}';

String _two(int v) => v.toString().padLeft(2, '0');

class _ReportsView extends StatelessWidget {
  const _ReportsView({required this.reports, required this.padding});

  final Reports reports;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final chart = _ChartCard(reports: reports);
    final payments = _PaymentsCard(summary: reports.summary);
    final top = _TopProductsCard(rows: reports.topProducts);
    final cashiers = _CashiersCard(rows: reports.cashiers);
    final debts = _DebtsCard(reports: reports);
    final stock = _StockCard(reports: reports);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 2 * padding;
        final wide = width >= 720;
        return ListView(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
          children: [
            _KpiGrid(summary: reports.summary, width: width),
            const SizedBox(height: PosSpacing.l),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _column([chart, top, cashiers]),
                  ),
                  const SizedBox(width: PosSpacing.l),
                  Expanded(
                    flex: 2,
                    child: _column([payments, debts, stock]),
                  ),
                ],
              )
            else
              _column([chart, payments, top, cashiers, debts, stock]),
          ],
        );
      },
    );
  }

  static Widget _column(List<Widget> cards) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, card) in cards.indexed) ...[
        if (i > 0) const SizedBox(height: PosSpacing.l),
        card,
      ],
    ],
  );
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary, required this.width});

  final ReportSummary summary;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final columns = width >= 900 ? 4 : 2;
    final cardWidth = (width - PosSpacing.m * (columns - 1)) / columns;
    final cards = [
      _Kpi(
        key: const ValueKey('reports-revenue'),
        label: l10n.reportsRevenue,
        value: PosMoneyText(
          amount: summary.revenueTiyin,
          currency: fmt.currency,
          size: PosMoneySize.large,
        ),
        changeBp: summary.revenueChangeBp,
        previous: fmt.money(summary.previousRevenueTiyin),
      ),
      _Kpi(
        key: const ValueKey('reports-profit'),
        label: l10n.reportsProfit,
        value: PosMoneyText(
          amount: summary.profitTiyin,
          currency: fmt.currency,
          size: PosMoneySize.medium,
          tone: summary.profitTiyin < 0 ? PosTone.danger : null,
        ),
        changeBp: summary.profitChangeBp,
        previous: fmt.money(summary.previousProfitTiyin),
      ),
      _Kpi(
        key: const ValueKey('reports-checks'),
        label: l10n.reportsChecks,
        value: _Number('${summary.salesCount}'),
        previous: '${summary.previousSalesCount}',
      ),
      _Kpi(
        key: const ValueKey('reports-average'),
        label: l10n.reportsAverageCheck,
        value: PosMoneyText(
          amount: summary.averageCheckTiyin,
          currency: fmt.currency,
          size: PosMoneySize.medium,
        ),
      ),
    ];
    return Wrap(
      spacing: PosSpacing.m,
      runSpacing: PosSpacing.m,
      children: [
        for (final card in cards) SizedBox(width: cardWidth, child: card),
      ],
    );
  }
}

class _Number extends StatelessWidget {
  const _Number(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: PosTypography.h2.copyWith(
      color: PosPalette.of(context).text,
      fontFeatures: PosTypography.tabular,
    ),
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    this.changeBp,
    this.previous,
    super.key,
  });

  final String label;
  final Widget value;
  final int? changeBp;
  final String? previous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final change = changeBp;
    final percent = change == null
        ? null
        : context.fmt.percent(Money.mulDivHalfUp(change.abs(), 1, 100));
    return PosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PosTypography.small.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: PosSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: value,
          ),
          if (previous != null) ...[
            const SizedBox(height: PosSpacing.s),
            Wrap(
              spacing: PosSpacing.s,
              runSpacing: PosSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (change != null && percent != null)
                  PosBadge(
                    label: change >= 0
                        ? l10n.reportsChangeUp(percent)
                        : l10n.reportsChangeDown(percent),
                    tone: change >= 0 ? PosTone.success : PosTone.danger,
                  ),
                Text(
                  l10n.reportsPrevious(previous!),
                  style: PosTypography.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return PosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: PosTypography.h3.copyWith(color: p.text),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: PosSpacing.m),
          child,
        ],
      ),
    );
  }
}

/// Qator: chapda nom (va izoh), o'ngda qiymat.
class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.detail,
    this.tone,
  });

  final String label;
  final String value;
  final String? detail;
  final PosTone? tone;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final t = tone;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: PosTypography.body.copyWith(color: p.text)),
                if (detail != null)
                  Text(
                    detail!,
                    style: PosTypography.small.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: PosSpacing.m),
          Text(
            value,
            style: PosTypography.bodyStrong.copyWith(
              color: t == null ? p.text : p.tone(t).text,
              fontFeatures: PosTypography.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: PosSpacing.s),
    child: Text(
      text,
      style: PosTypography.small.copyWith(
        color: PosPalette.of(context).textMuted,
      ),
    ),
  );
}

/// Bir kun — soatlar bo'yicha, ko'p kun — kunlar bo'yicha ustunlar.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.reports});

  final Reports reports;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final hourly = reports.period.dayCount == 1;
    final List<(String, int)> bars;
    if (hourly) {
      final busy = [
        for (final h in reports.byHour)
          if (h.revenueTiyin != 0 || h.salesCount != 0) h.hour,
      ];
      final first = math.min(busy.isEmpty ? 8 : busy.first, 8);
      final last = math.max(busy.isEmpty ? 20 : busy.last, 20);
      bars = [
        for (final h in reports.byHour)
          if (h.hour >= first && h.hour <= last) (_two(h.hour), h.revenueTiyin),
      ];
    } else {
      bars = [
        for (final d in reports.byDay)
          ('${_two(d.date.day)}.${_two(d.date.month)}', d.revenueTiyin),
      ];
    }
    final empty = reports.summary.salesCount == 0;
    return _SectionCard(
      key: const ValueKey('reports-chart'),
      title: hourly ? l10n.reportsByHour : l10n.reportsByDay,
      child: empty
          ? _Empty(l10n.reportsNoSales)
          : _Bars(
              bars: bars,
              tooltip: (i) => fmt.money(bars[i].$2),
            ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.bars, required this.tooltip});

  final List<(String, int)> bars;
  final String Function(int index) tooltip;

  static const double _height = 160;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final max = bars.fold<int>(1, (m, b) => math.max(m, b.$2));
    // Yorliqlar ustma-ust tushmasin: ko'p ustunda har n-chisi.
    final every = (bars.length / 12).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, (_, value)) in bars.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                      label: tooltip(i),
                      child: Container(
                        height: value <= 0
                            ? 2
                            : math.max(2, _height * value / max),
                        decoration: BoxDecoration(
                          color: value <= 0 ? p.border : p.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(PosRadius.input / 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: PosSpacing.xs),
        Row(
          children: [
            for (final (i, (label, _)) in bars.indexed)
              Expanded(
                child: Text(
                  i % every == 0 ? label : '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: PosTypography.caption.copyWith(color: p.textMuted),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final pay = summary.paymentsTiyin;
    return _SectionCard(
      key: const ValueKey('reports-payments'),
      title: l10n.reportsPayments,
      child: Column(
        children: [
          _Line(label: l10n.reportCash, value: fmt.money(pay['cash'] ?? 0)),
          _Line(label: l10n.reportCard, value: fmt.money(pay['card'] ?? 0)),
          _Line(label: l10n.reportDebt, value: fmt.money(pay['debt'] ?? 0)),
          _Line(
            label: l10n.reportRefunds,
            value: fmt.money(summary.refundsTotalTiyin),
            tone: summary.refundsTotalTiyin > 0 ? PosTone.danger : null,
          ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends ConsumerWidget {
  const _TopProductsCard({required this.rows});

  final List<ProductReportRow> rows;

  static const int limit = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final units =
        ref.watch(productUnitsProvider).value ?? const <String, UnitCode>{};
    return _SectionCard(
      key: const ValueKey('reports-top'),
      title: l10n.reportsTopProducts,
      child: rows.isEmpty
          ? _Empty(l10n.reportsNothing)
          : Column(
              children: [
                for (final r in rows.take(limit))
                  _Line(
                    label: r.name,
                    detail: fmt.qty(
                      r.qtyMilli,
                      units[r.productId] ?? UnitCode.pcs,
                    ),
                    value: fmt.money(r.revenueTiyin),
                  ),
              ],
            ),
    );
  }
}

class _CashiersCard extends StatelessWidget {
  const _CashiersCard({required this.rows});

  final List<CashierReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    return _SectionCard(
      key: const ValueKey('reports-cashiers'),
      title: l10n.reportsCashiers,
      child: rows.isEmpty
          ? _Empty(l10n.reportsNothing)
          : Column(
              children: [
                for (final c in rows)
                  _Line(
                    label: c.fullName,
                    detail: c.refundsCount == 0
                        ? l10n.reportChecks(c.salesCount)
                        : l10n.reportsCashierLine(
                            l10n.reportChecks(c.salesCount),
                            l10n.reportsCashierRefunds(c.refundsCount),
                          ),
                    value: fmt.money(c.salesTotalTiyin),
                  ),
              ],
            ),
    );
  }
}

class _DebtsCard extends StatelessWidget {
  const _DebtsCard({required this.reports});

  final Reports reports;

  static const int limit = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    return _SectionCard(
      key: const ValueKey('reports-debts'),
      title: l10n.reportsDebts,
      trailing: PosMoneyText(
        amount: reports.totalDebtTiyin,
        currency: fmt.currency,
        tone: reports.totalDebtTiyin > 0 ? PosTone.danger : null,
      ),
      child: reports.debtorsCount == 0
          ? _Empty(l10n.reportsNothing)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Empty(l10n.reportsDebtors(reports.debtorsCount)),
                for (final d in reports.topDebtors.take(limit))
                  _Line(
                    label: d.fullName,
                    detail: d.phone.isEmpty ? null : d.phone,
                    value: fmt.money(d.balanceTiyin),
                    tone: PosTone.danger,
                  ),
              ],
            ),
    );
  }
}

class _StockCard extends ConsumerWidget {
  const _StockCard({required this.reports});

  final Reports reports;

  static const int limit = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final units =
        ref.watch(productUnitsProvider).value ?? const <String, UnitCode>{};
    String qty(StockRow r) =>
        fmt.qty(r.qtyMilli, units[r.productId] ?? UnitCode.pcs);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: PosSpacing.m),
      child: Text(
        text,
        style: PosTypography.smallStrong.copyWith(color: p.text),
      ),
    );
    return _SectionCard(
      key: const ValueKey('reports-stock'),
      title: l10n.reportsStock,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line(
            label: l10n.reportsStockValue,
            value: fmt.money(reports.stockValueTiyin),
          ),
          heading(l10n.reportsLowStock),
          if (reports.low.isEmpty) _Empty(l10n.reportsNothing),
          for (final r in reports.low.take(limit))
            _Line(
              label: r.name,
              value: qty(r),
              detail: l10n.reportsStockLine(
                qty(r),
                fmt.qty(r.minStockMilli, units[r.productId] ?? UnitCode.pcs),
              ),
              tone: PosTone.warning,
            ),
          if (reports.negative.isNotEmpty) ...[
            heading(l10n.reportsNegativeStock),
            for (final r in reports.negative.take(limit))
              _Line(label: r.name, value: qty(r), tone: PosTone.danger),
          ],
        ],
      ),
    );
  }
}
