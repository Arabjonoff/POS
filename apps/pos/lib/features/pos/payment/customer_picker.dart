import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/text/phone.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Mijoz tanlash: qidiruv (ism/telefon), ro'yxat (qarz va limit bilan),
/// "Yangi mijoz" — ism va telefon bilan tez yaratish (`debts.md`).
class CustomerPicker extends ConsumerStatefulWidget {
  const CustomerPicker({
    required this.onSelected,
    this.selectedId,
    this.listHeight = 240,
    super.key,
  });

  final ValueChanged<CustomerEntry> onSelected;
  final String? selectedId;
  final double listHeight;

  @override
  ConsumerState<CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends ConsumerState<CustomerPicker> {
  final _query = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _creating = false;
  bool _saving = false;
  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _query.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = l10n.fieldRequired);
      return;
    }
    if (normalizePhone(_phone.text) == null) {
      setState(() => _phoneError = l10n.phoneInvalid);
      return;
    }
    final user = ref.read(sessionProvider).user;
    if (user == null || _saving) return;
    setState(() => _saving = true);
    try {
      final created = await ref
          .read(customerDirectoryProvider)
          .create(name: _name.text, phone: _phone.text, createdBy: user.id);
      if (!mounted) return;
      setState(() => _creating = false);
      widget.onSelected(created);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_creating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosTextField(
            controller: _name,
            label: l10n.payCustomerName,
            errorText: _nameError,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: PosSpacing.s),
          PosTextField(
            controller: _phone,
            label: l10n.payCustomerPhone,
            keyboardType: TextInputType.phone,
            errorText: _phoneError,
            onChanged: (_) => setState(() => _phoneError = null),
            onSubmitted: (_) => unawaited(_create()),
          ),
          const SizedBox(height: PosSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PosButton(
                label: l10n.actionCancel,
                variant: PosButtonVariant.ghost,
                onPressed: () => setState(() => _creating = false),
              ),
              const SizedBox(width: PosSpacing.s),
              PosButton(
                label: l10n.actionSave,
                loading: _saving,
                onPressed: () => unawaited(_create()),
              ),
            ],
          ),
        ],
      );
    }

    final all = ref.watch(customersProvider).value ?? const <CustomerEntry>[];
    final found = CustomerDirectory.filter(all, _query.text);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PosSearchField(
                controller: _query,
                hint: l10n.payCustomerSearch,
                clearTooltip: l10n.actionClear,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: PosSpacing.s),
            PosButton(
              label: l10n.payNewCustomer,
              icon: Icons.person_add_alt_1_outlined,
              variant: PosButtonVariant.secondary,
              onPressed: () => setState(() {
                _creating = true;
                _name.text = _query.text;
              }),
            ),
          ],
        ),
        const SizedBox(height: PosSpacing.s),
        SizedBox(
          height: widget.listHeight,
          child: found.isEmpty
              ? PosEmptyState(
                  icon: Icons.person_search_outlined,
                  title: l10n.payNoCustomers,
                )
              : ListView.builder(
                  itemCount: found.length,
                  itemBuilder: (context, i) => CustomerTile(
                    customer: found[i],
                    selected: found[i].id == widget.selectedId,
                    onTap: () => widget.onSelected(found[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Mijoz qatori: ism, telefon, qarz va limit.
class CustomerTile extends StatelessWidget {
  const CustomerTile({
    required this.customer,
    this.selected = false,
    this.onTap,
    this.trailing,
    super.key,
  });

  final CustomerEntry customer;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final limit = customer.limitTiyin;
    final details = [
      if (customer.phone.isNotEmpty) customer.phone,
      l10n.payCustomerDebt(fmt.money(customer.balanceTiyin)),
      if (limit != null) l10n.payCustomerLimit(fmt.money(limit)),
    ];
    return PosListTile(
      leading: const Icon(Icons.person_outline),
      title: customer.name,
      subtitle: details.join(' · '),
      selected: selected,
      onTap: onTap,
      trailing: trailing,
    );
  }
}

/// F4 natijasi: [customer] `null` — chekdan mijozni olib tashlash.
class CustomerChoice {
  const CustomerChoice(this.customer);

  final CustomerEntry? customer;
}

/// F4: chek mijozi (nasiyada oldindan tanlangan bo'ladi).
Future<CustomerChoice?> showCustomerDialog(
  BuildContext context, {
  String? selectedId,
}) => showPosDialog<CustomerChoice>(
  context: context,
  builder: (context) => PosDialog(
    icon: Icons.person_outline,
    title: AppLocalizations.of(context).posCustomerTitle,
    content: CustomerPicker(
      selectedId: selectedId,
      onSelected: (c) => Navigator.of(context).pop(CustomerChoice(c)),
    ),
    actions: [
      if (selectedId != null)
        PosButton(
          label: AppLocalizations.of(context).posCustomerRemove,
          variant: PosButtonVariant.ghost,
          onPressed: () =>
              Navigator.of(context).pop(const CustomerChoice(null)),
        ),
      PosButton(
        label: AppLocalizations.of(context).actionCancel,
        variant: PosButtonVariant.secondary,
        shortcut: 'Esc',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  ),
);
