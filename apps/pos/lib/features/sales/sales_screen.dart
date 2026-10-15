import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/status/app_status.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/time/store_time_zone.dart';
import 'package:pos_app/data/sales/sale_history.dart';
import 'package:pos_app/features/common/load_state.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/sales/sale_detail.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

enum _Day { today, yesterday, picked }

/// Bo'lim "Cheklar" (Ctrl+7, kassada F7; `receipt-history.md`): shu
/// kassaning yakunlangan cheklari, chek ko'rinishi, qayta chop etish,
/// qaytarish.
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  /// Keng ekranda o'ngdagi chek paneli.
  static const double detailWidth = 440;

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode(debugLabel: 'sales');
  _Day _day = _Day.today;
  DateTime? _picked;
  SalePaymentFilter _payment = SalePaymentFilter.all;
  String? _openId;

  /// Oyna (qaytarish) ochiq — skaner unga tegishli.
  bool _dialogOpen = false;

  bool _wasActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusScreen());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bo'lim almashganda fokus yo'qoladi — Esc/Ctrl+P ishlashi uchun qaytaramiz.
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_wasActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusScreen());
    } else if (!active && _wasActive && _focus.hasFocus) {
      // Yashirin bo'lim fokusni ushlab qolmasin (kassa F-tugmalari).
      _focus.unfocus();
    }
    _wasActive = active;
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _focusScreen() {
    if (!mounted || _dialogOpen || !TickerMode.valuesOf(context).enabled) {
      return;
    }
    _focus.requestFocus();
  }

  void _open(String? id) {
    setState(() => _openId = id);
    if (id == null) _focusScreen();
  }

  DateTime get _today =>
      StoreTimeZone.tashkent.today(ref.read(clockProvider)());

  DateTime get _selectedDay => switch (_day) {
    _Day.today => _today,
    _Day.yesterday => _today.subtract(const Duration(days: 1)),
    _Day.picked => _picked ?? _today,
  };

  SaleHistoryFilter get _filter => SaleHistoryFilter(
    day: _selectedDay,
    query: _search.text,
    payment: _payment,
  );

  /// Chekdagi shtrix-kod — o'sha chek; boshqa kod (tovar) — qidiruvga.
  Future<void> _onScan(ScanEvent event) async {
    final id = await ref
        .read(saleHistoryRepositoryProvider)
        .idByNumber(event.code);
    if (!mounted) return;
    if (id != null) {
      _open(id);
      return;
    }
    if (event.code.toUpperCase().contains('-')) {
      showPosToast(
        context,
        message: AppLocalizations.of(
          context,
        ).salesReceiptNotFound(event.code.toUpperCase()),
        tone: PosTone.warning,
      );
      return;
    }
    setState(() => _search.text = event.code);
  }

  void _onTyping(String text) {
    final value = _search.text + text;
    _search.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  void _escape() {
    if (_openId != null) {
      _open(null);
    } else if (_search.text.isNotEmpty) {
      setState(_search.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final history = ref.watch(saleHistoryProvider(_filter));
    final page = history.value;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _escape,
      },
      child: Focus(
        focusNode: _focus,
        child: ScanListener(
          enabled: !_dialogOpen,
          onScan: (e) => unawaited(_onScan(e)),
          onTyping: _onTyping,
          child: SectionPage(
            title: l10n.navSales,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >=
                    SalesScreen.detailWidth * 2 + PosSpacing.xl;
                final openId = _openId;
                final detail = openId == null
                    ? null
                    : SaleDetail(
                        key: ValueKey('sale-detail-$openId'),
                        saleId: openId,
                        onClose: wide ? null : () => _open(null),
                        onDialog: (open) => setState(() => _dialogOpen = open),
                      );
                if (!wide && detail != null) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
                    child: detail,
                  );
                }
                final list = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _filters(l10n),
                    const SizedBox(height: PosSpacing.m),
                    if (page != null) _summary(l10n, page),
                    const SizedBox(height: PosSpacing.s),
                    Expanded(child: _list(l10n, history, page)),
                  ],
                );
                if (!wide) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
                    child: list,
                  );
                }
                return Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: list),
                      const SizedBox(width: PosSpacing.l),
                      SizedBox(
                        width: SalesScreen.detailWidth,
                        child:
                            detail ??
                            Center(
                              child: PosEmptyState(
                                icon: Icons.receipt_outlined,
                                title: l10n.salesSelectHint,
                                compact: true,
                              ),
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _filters(AppLocalizations l10n) {
    final fmt = context.fmt;
    Widget chip<T>(String label, T value, T selected, ValueChanged<T> onTap) =>
        PosButton(
          key: ValueKey('sales-filter-$value'),
          label: label,
          size: PosButtonSize.s,
          variant: value == selected
              ? PosButtonVariant.primary
              : PosButtonVariant.secondary,
          onPressed: () => onTap(value),
        );
    final searching = _search.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PosSearchField(
          key: const ValueKey('sales-search'),
          controller: _search,
          hint: l10n.salesSearchHint,
          clearTooltip: l10n.actionClear,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: PosSpacing.s),
        Wrap(
          spacing: PosSpacing.s,
          runSpacing: PosSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!searching) ...[
              chip(
                l10n.reportsToday,
                _Day.today,
                _day,
                (d) => setState(() => _day = d),
              ),
              chip(
                l10n.reportsYesterday,
                _Day.yesterday,
                _day,
                (d) => setState(() => _day = d),
              ),
              SizedBox(
                width: 180,
                child: PosDateField(
                  key: const ValueKey('sales-date'),
                  value: _selectedDay,
                  firstDate: DateTime(2020),
                  lastDate: _today,
                  format: fmt.date,
                  onChanged: (d) => setState(() {
                    _picked = DateTime.utc(d.year, d.month, d.day);
                    _day = _picked == _today ? _Day.today : _Day.picked;
                  }),
                ),
              ),
            ],
            for (final (value, label) in [
              (SalePaymentFilter.all, l10n.salesAllPayments),
              (SalePaymentFilter.cash, l10n.payCash),
              (SalePaymentFilter.card, l10n.payCard),
              (SalePaymentFilter.debt, l10n.payDebt),
            ])
              chip(
                label,
                value,
                _payment,
                (v) => setState(() => _payment = v),
              ),
          ],
        ),
      ],
    );
  }

  Widget _summary(AppLocalizations l10n, SaleHistoryPage page) {
    final p = PosPalette.of(context);
    final fmt = context.fmt;
    return Wrap(
      spacing: PosSpacing.m,
      children: [
        Text(
          l10n.salesSummary(page.entries.length, fmt.money(page.totalTiyin)),
          key: const ValueKey('sales-summary'),
          style: PosTypography.bodyStrong.copyWith(color: p.text),
        ),
        if (page.refundedTiyin > 0)
          Text(
            l10n.salesRefundedTotal(fmt.money(page.refundedTiyin)),
            style: PosTypography.body.copyWith(color: p.dangerText),
          ),
      ],
    );
  }

  Widget _list(
    AppLocalizations l10n,
    AsyncValue<SaleHistoryPage> history,
    SaleHistoryPage? page,
  ) {
    if (page == null) {
      return LoadState(
        failed: history.hasError,
        onRetry: () => ref.invalidate(saleHistoryProvider(_filter)),
      );
    }
    final p = PosPalette.of(context);
    final searching = _search.text.trim().isNotEmpty;
    if (page.entries.isEmpty) {
      return PosEmptyState(
        icon: searching ? Icons.search_off : Icons.receipt_outlined,
        title: searching ? l10n.salesNotFound : l10n.salesEmptyTitle,
        message: l10n.salesLocalNote,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: PosSpacing.l),
      itemCount: page.entries.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: PosSpacing.s),
      itemBuilder: (context, i) {
        if (i == page.entries.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: PosSpacing.s),
            child: Text(
              l10n.salesLocalNote,
              textAlign: TextAlign.center,
              style: PosTypography.small.copyWith(color: p.textMuted),
            ),
          );
        }
        final entry = page.entries[i];
        return _SaleRow(
          entry: entry,
          showDate: searching,
          selected: entry.id == _openId,
          onTap: () => _open(entry.id),
        );
      },
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({
    required this.entry,
    required this.showDate,
    required this.selected,
    required this.onTap,
  });

  final SaleHistoryEntry entry;
  final bool showDate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final meta = [
      if (showDate) fmt.dateTime(entry.soldAt) else fmt.time(entry.soldAt),
      if (entry.cashierName.isNotEmpty) entry.cashierName,
      if (entry.customerName != null) entry.customerName!,
    ].join(' · ');
    final detail = [
      l10n.salesItems(entry.itemCount),
      for (final m in entry.methods) salePaymentLabel(l10n, m),
    ].join(' · ');
    return PosCard(
      key: ValueKey('sale-${entry.number}'),
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: PosSpacing.s,
                  runSpacing: PosSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      entry.number,
                      style: PosTypography.bodyStrong.copyWith(color: p.text),
                    ),
                    ?saleStatusBadge(l10n, entry),
                  ],
                ),
                const SizedBox(height: PosSpacing.xs),
                Text(
                  meta,
                  style: PosTypography.small.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: PosSpacing.m),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PosMoneyText(amount: entry.totalTiyin, currency: fmt.currency),
              const SizedBox(height: PosSpacing.xs),
              Text(
                detail,
                style: PosTypography.small.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// To'lov turi nomi (`cash` / `card` / `debt`).
String salePaymentLabel(AppLocalizations l10n, String method) =>
    switch (method) {
      'card' => l10n.payCard,
      'debt' => l10n.payDebt,
      _ => l10n.payCash,
    };

/// "Qaytarilgan" / "Qisman qaytarilgan" belgisi (oddiy chekda — yo'q).
Widget? saleStatusBadge(AppLocalizations l10n, SaleHistoryEntry entry) {
  if (entry.refunded) {
    return PosBadge(label: l10n.salesStatusRefunded, tone: PosTone.danger);
  }
  if (entry.partiallyRefunded) {
    return PosBadge(label: l10n.salesStatusPartial, tone: PosTone.warning);
  }
  return null;
}
