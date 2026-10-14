import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/customers/customer_card.dart';
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
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final phone = TextEditingController();
    final created = await showPosDialog<bool>(
      context: context,
      builder: (context) => PosDialog(
        icon: Icons.person_add_alt_1_outlined,
        title: l10n.customersAdd,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosTextField(
              key: const ValueKey('new-customer-name'),
              controller: name,
              label: l10n.payCustomerName,
              autofocus: true,
            ),
            const SizedBox(height: PosSpacing.s),
            PosTextField(
              controller: phone,
              label: l10n.payCustomerPhone,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          PosButton(
            label: l10n.actionCancel,
            variant: PosButtonVariant.secondary,
            shortcut: 'Esc',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          PosButton(
            key: const ValueKey('new-customer-save'),
            label: l10n.actionSave,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    final user = ref.read(sessionProvider).user;
    if (created == true && name.text.trim().isNotEmpty && user != null) {
      final entry = await ref
          .read(customerDirectoryProvider)
          .create(name: name.text, phone: phone.text, createdBy: user.id);
      if (mounted) setState(() => _openId = entry.id);
    }
    name.dispose();
    phone.dispose();
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
    final all = ref.watch(customersProvider).value;
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
      body = const Center(child: CircularProgressIndicator());
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
            child: Row(
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
                const Spacer(),
                Flexible(
                  child: Text(
                    l10n.customersTotalDebt(fmt.money(totalDebt)),
                    key: const ValueKey('customers-total'),
                    textAlign: TextAlign.right,
                    style: PosTypography.bodyStrong.copyWith(color: p.text),
                  ),
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
