import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/money/grouped_money_formatter.dart';
import 'package:pos_app/core/text/phone.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/features/common/load_state.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/customers/customer_card.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Qarzdorlar birinchi (qarz kamayib), keyin ism (`debts.md`).
List<CustomerEntry> sortDebtorsFirst(List<CustomerEntry> all) =>
    [...all]..sort((a, b) {
      final debtA = a.balanceTiyin > 0 ? a.balanceTiyin : 0;
      final debtB = b.balanceTiyin > 0 ? b.balanceTiyin : 0;
      if (debtA != debtB) return debtB.compareTo(debtA);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

/// Bo'lim "Mijozlar" (Ctrl+4): ro'yxat va mijoz kartasi.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();
  bool _debtorsOnly = false;
  String? _openId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _new() async {
    final result = await showPosDialog<NewCustomerInput>(
      context: context,
      builder: (context) => const _NewCustomerDialog(),
    );
    final user = ref.read(sessionProvider).user;
    if (result == null || user == null || !mounted) return;
    OpeningBalanceInput? opening;
    if (result.openingKind != OpeningKind.none) {
      final credit = result.openingKind == OpeningKind.credit;
      String? approvedBy;
      // Soxta avans bilan nasiyaga tovar olish mumkin — kassir uchun menejer PIN.
      if (credit && !DiscountPolicy.canApprove(user.role)) {
        approvedBy = await requestManagerApproval(
          context,
          reason: AppLocalizations.of(context).customerOpeningNeedsApproval,
        );
        if (approvedBy == null || !mounted) return;
      }
      opening = OpeningBalanceInput(
        amountTiyin: result.openingTiyin,
        at: result.openingAt!,
        credit: credit,
        approvedBy: approvedBy,
      );
    }
    final entry = await ref
        .read(customerDirectoryProvider)
        .create(
          name: result.name,
          phone: result.phone,
          createdBy: user.id,
          opening: opening,
        );
    if (mounted) setState(() => _openId = entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final openId = _openId;
    if (openId != null) {
      return CustomerCard(
        key: ValueKey(openId),
        customerId: openId,
        onClose: () => setState(() => _openId = null),
      );
    }
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final customers = ref.watch(customersProvider);
    final all = customers.value;
    final totalDebt = (all ?? const <CustomerEntry>[]).fold(
      0,
      (s, c) => s + (c.balanceTiyin > 0 ? c.balanceTiyin : 0),
    );
    final found = all == null
        ? null
        : sortDebtorsFirst([
            for (final c in CustomerDirectory.filter(all, _search.text))
              if (!_debtorsOnly || c.balanceTiyin > 0) c,
          ]);

    final Widget body;
    if (found == null) {
      body = LoadState(
        failed: customers.hasError,
        onRetry: () => ref.invalidate(customersProvider),
      );
    } else if (all!.isEmpty) {
      body = PosEmptyState(
        icon: Icons.people_outline,
        title: l10n.customersEmptyTitle,
        message: l10n.customersEmptyMessage,
      );
    } else if (found.isEmpty) {
      body = PosEmptyState(
        icon: Icons.person_search_outlined,
        title: l10n.customersNotFound,
      );
    } else {
      body = ListView.separated(
        padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
        itemCount: found.length,
        separatorBuilder: (_, _) => const SizedBox(height: PosSpacing.s),
        itemBuilder: (context, i) {
          final c = found[i];
          return PosCard(
            key: ValueKey('customer-${c.id}'),
            onTap: () => setState(() => _openId = c.id),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: PosTypography.bodyStrong.copyWith(color: p.text),
                      ),
                      if (c.phone.isNotEmpty)
                        Text(
                          c.phone,
                          style: PosTypography.small.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (c.balanceTiyin > 0)
                  PosMoneyText(
                    amount: c.balanceTiyin,
                    currency: fmt.currency,
                    tone: PosTone.danger,
                  )
                else if (c.balanceTiyin < 0)
                  Text(
                    l10n.customerCreditShort(fmt.money(-c.balanceTiyin)),
                    style: PosTypography.small.copyWith(color: p.successText),
                  )
                else
                  Text(
                    l10n.customerNoDebt,
                    style: PosTypography.small.copyWith(color: p.textMuted),
                  ),
              ],
            ),
          );
        },
      );
    }

    Widget chip(String label, {required bool selected, required Key key}) =>
        Padding(
          padding: const EdgeInsets.only(right: PosSpacing.s),
          child: PosButton(
            key: key,
            label: label,
            size: PosButtonSize.s,
            variant: selected
                ? PosButtonVariant.primary
                : PosButtonVariant.secondary,
            onPressed: () => setState(() => _debtorsOnly = !_debtorsOnly),
          ),
        );

    return SectionPage(
      title: l10n.navCustomers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, PosSpacing.s),
            child: Row(
              children: [
                Expanded(
                  child: PosSearchField(
                    key: const ValueKey('customers-search'),
                    controller: _search,
                    hint: l10n.customersSearchHint,
                    clearTooltip: l10n.actionClear,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: PosSpacing.s),
                if (compact)
                  PosIconButton(
                    key: const ValueKey('customers-add'),
                    icon: Icons.person_add_alt_1_outlined,
                    tooltip: l10n.customersAdd,
                    variant: PosIconButtonVariant.filled,
                    onPressed: () => unawaited(_new()),
                  )
                else
                  PosButton(
                    key: const ValueKey('customers-add'),
                    label: l10n.customersAdd,
                    icon: Icons.person_add_alt_1_outlined,
                    onPressed: () => unawaited(_new()),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, PosSpacing.m),
            child: Wrap(
              spacing: PosSpacing.s,
              runSpacing: PosSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    chip(
                      l10n.customersAll,
                      key: const ValueKey('customers-all'),
                      selected: !_debtorsOnly,
                    ),
                    chip(
                      l10n.customersDebtorsOnly,
                      key: const ValueKey('customers-debtors'),
                      selected: _debtorsOnly,
                    ),
                  ],
                ),
                Text(
                  l10n.customersTotalDebt(fmt.money(totalDebt)),
                  key: const ValueKey('customers-total'),
                  style: PosTypography.bodyStrong.copyWith(color: p.text),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Boshlang'ich balans yo'nalishi (T-103).
enum OpeningKind { none, debt, credit }

/// Yangi mijoz formasi natijasi.
class NewCustomerInput {
  const NewCustomerInput({
    required this.name,
    required this.phone,
    this.openingKind = OpeningKind.none,
    this.openingTiyin = 0,
    this.openingAt,
  });

  final String name;
  final String phone;
  final OpeningKind openingKind;
  final int openingTiyin;
  final DateTime? openingAt;
}

/// Yangi mijoz: ism (majburiy), telefon (ixtiyoriy) va boshlang'ich balans —
/// do'kon ilgari ishlagan bo'lsa, mijozning eski qarzi yoki avansi (T-103).
class _NewCustomerDialog extends StatefulWidget {
  const _NewCustomerDialog();

  @override
  State<_NewCustomerDialog> createState() => _NewCustomerDialogState();
}

class _NewCustomerDialogState extends State<_NewCustomerDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  String? _error;
  String? _phoneError;
  String? _amountError;
  OpeningKind _kind = OpeningKind.none;
  late DateTime _date = _today();
  bool _saved = false;

  static DateTime _today() {
    final now = clock.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    // Enter va tugma bir vaqtda — oyna ikki marta yopilmasin (audit CU-B6).
    if (_saved) return;
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }
    final phone = normalizePhone(_phone.text);
    if (phone == null) {
      setState(() => _phoneError = l10n.phoneInvalid);
      return;
    }
    final amount = GroupedMoneyFormatter.parseTiyin(_amount.text) ?? 0;
    if (_kind != OpeningKind.none && amount <= 0) {
      setState(() => _amountError = l10n.customerOpeningAmountRequired);
      return;
    }
    // Bugun — hozirgi vaqt (kelajak bo'lmasin); o'tgan sana — kun o'rtasi.
    final now = clock.now();
    final at = _date == _today()
        ? now
        : DateTime(_date.year, _date.month, _date.day, 12);
    _saved = true;
    Navigator.of(context).pop(
      NewCustomerInput(
        name: _name.text,
        phone: phone,
        openingKind: _kind,
        openingTiyin: _kind == OpeningKind.none ? 0 : amount,
        openingAt: _kind == OpeningKind.none ? null : at,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final hint = switch (_kind) {
      OpeningKind.none => l10n.customerOpeningNoneHint,
      OpeningKind.debt => l10n.customerOpeningDebtHint,
      OpeningKind.credit => l10n.customerOpeningCreditHint,
    };
    return PosDialog(
      icon: Icons.person_add_alt_1_outlined,
      title: l10n.customersAdd,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosTextField(
            key: const ValueKey('new-customer-name'),
            controller: _name,
            label: l10n.payCustomerName,
            required: true,
            autofocus: true,
            errorText: _error,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: PosSpacing.s),
          PosTextField(
            key: const ValueKey('new-customer-phone'),
            controller: _phone,
            label: l10n.fieldOptional(l10n.payCustomerPhone),
            keyboardType: TextInputType.phone,
            errorText: _phoneError,
            onChanged: (_) => setState(() => _phoneError = null),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: PosSpacing.l),
          PosSegmentedControl<OpeningKind>(
            key: const ValueKey('new-customer-opening'),
            label: l10n.customerOpeningSection,
            helper: hint,
            selected: _kind,
            segments: [
              PosSegment(
                key: const ValueKey('opening-none'),
                value: OpeningKind.none,
                label: l10n.customerOpeningNone,
              ),
              PosSegment(
                key: const ValueKey('opening-debt'),
                value: OpeningKind.debt,
                label: l10n.customerOpeningDebt,
              ),
              PosSegment(
                key: const ValueKey('opening-credit'),
                value: OpeningKind.credit,
                label: l10n.customerOpeningCredit,
              ),
            ],
            onChanged: (kind) => setState(() {
              _kind = kind;
              _amountError = null;
            }),
          ),
          if (_kind != OpeningKind.none) ...[
            const SizedBox(height: PosSpacing.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PosTextField(
                    key: const ValueKey('new-customer-opening-amount'),
                    controller: _amount,
                    label: l10n.customerOpeningAmount(fmt.currency),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    inputFormatters: const [GroupedMoneyFormatter()],
                    errorText: _amountError,
                    onChanged: (_) => setState(() => _amountError = null),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                const SizedBox(width: PosSpacing.s),
                Expanded(
                  child: PosDateField(
                    key: const ValueKey('new-customer-opening-date'),
                    label: l10n.customerOpeningDate,
                    value: _date,
                    firstDate: DateTime(2000),
                    lastDate: _today(),
                    format: fmt.date,
                    onChanged: (d) => setState(() => _date = d),
                  ),
                ),
              ],
            ),
          ],
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
          key: const ValueKey('new-customer-save'),
          label: l10n.actionSave,
          onPressed: _save,
        ),
      ],
    );
  }
}
