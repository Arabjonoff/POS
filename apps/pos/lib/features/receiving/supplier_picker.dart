import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/receipts/receipt_store.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Tanlov: [supplierId] `null` — yetkazib beruvchisiz.
class SupplierChoice {
  const SupplierChoice(this.supplierId);

  final String? supplierId;
}

final suppliersProvider = StreamProvider<List<SupplierEntry>>(
  (ref) => ref.watch(receiptStoreProvider).watchSuppliers(),
);

/// Yetkazib beruvchi: ro'yxat va tez yaratish (ega/menejer yoki PIN).
Future<SupplierChoice?> showSupplierPicker(
  BuildContext context, {
  String? selectedId,
}) => showPosDialog<SupplierChoice>(
  context: context,
  builder: (context) => _SupplierPicker(selectedId: selectedId),
);

class _SupplierPicker extends ConsumerStatefulWidget {
  const _SupplierPicker({this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<_SupplierPicker> createState() => _SupplierPickerState();
}

class _SupplierPickerState extends ConsumerState<_SupplierPicker> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _creating = false;
  String? _nameError;

  @override
  void dispose() {
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
    final user = ref.read(sessionProvider).user;
    if (user == null) return;
    var by = DiscountPolicy.canApprove(user.role) ? user.id : null;
    by ??= await requestManagerApproval(
      context,
      reason: l10n.receivingNeedsApproval,
    );
    if (by == null || !mounted) return;
    final id = await ref
        .read(receiptStoreProvider)
        .createSupplier(name: _name.text, phone: _phone.text, by: by);
    if (mounted) Navigator.of(context).pop(SupplierChoice(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suppliers =
        ref.watch(suppliersProvider).value ?? const <SupplierEntry>[];
    return PosDialog(
      icon: Icons.local_shipping_outlined,
      title: _creating ? l10n.receivingNewSupplier : l10n.receivingSupplier,
      content: _creating
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosTextField(
                  key: const ValueKey('supplier-name'),
                  controller: _name,
                  label: l10n.payCustomerName,
                  autofocus: true,
                  errorText: _nameError,
                  onChanged: (_) => setState(() => _nameError = null),
                ),
                const SizedBox(height: PosSpacing.s),
                PosTextField(
                  controller: _phone,
                  label: l10n.payCustomerPhone,
                  keyboardType: TextInputType.phone,
                  onSubmitted: (_) => unawaited(_create()),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: l10n.receivingNoSupplier,
                  selected: widget.selectedId == null,
                  onTap: () =>
                      Navigator.of(context).pop(const SupplierChoice(null)),
                ),
                for (final s in suppliers)
                  PosListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: s.name,
                    subtitle: s.phone.isEmpty ? null : s.phone,
                    selected: s.id == widget.selectedId,
                    onTap: () =>
                        Navigator.of(context).pop(SupplierChoice(s.id)),
                  ),
              ],
            ),
      actions: [
        PosButton(
          label: l10n.actionCancel,
          variant: PosButtonVariant.secondary,
          shortcut: 'Esc',
          onPressed: () => _creating
              ? setState(() => _creating = false)
              : Navigator.of(context).pop(),
        ),
        if (_creating)
          PosButton(
            key: const ValueKey('supplier-save'),
            label: l10n.actionSave,
            onPressed: () => unawaited(_create()),
          )
        else
          PosButton(
            key: const ValueKey('supplier-new'),
            label: l10n.receivingNewSupplier,
            icon: Icons.add,
            onPressed: () => setState(() => _creating = true),
          ),
      ],
    );
  }
}
