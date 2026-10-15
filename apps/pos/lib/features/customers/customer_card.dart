import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/text/phone.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/common/money_input.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/products/product_card.dart'
    show formatMoneyInput, parseMoneyTiyin;
import 'package:pos_app/features/shift/shift_providers.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

final StreamProviderFamily<List<DebtRecord>, String> debtHistoryProvider =
    StreamProvider.autoDispose.family<List<DebtRecord>, String>(
      (ref, id) => ref.watch(customerDirectoryProvider).watchHistory(id),
    );

final StreamProviderFamily<List<PurchaseRecord>, String> purchasesProvider =
    StreamProvider.autoDispose.family<List<PurchaseRecord>, String>(
      (ref, id) => ref.watch(customerDirectoryProvider).watchPurchases(id),
    );

/// Mijoz kartasi (`debts.md`): katta qarz, limit, qarz tarixi, xaridlar,
/// qarzni to'lash, tahrirlash. Balans — doim qarz daftari yig'indisi.
class CustomerCard extends ConsumerWidget {
  const CustomerCard({
    required this.customerId,
    required this.onClose,
    super.key,
  });

  final String customerId;
  final VoidCallback onClose;

  static String _type(AppLocalizations l10n, String type, int amount) =>
      switch (type) {
        'sale' => l10n.debtSale,
        'payment' => l10n.debtPayment,
        'refund' => l10n.debtRefund,
        'opening' => amount > 0 ? l10n.debtOpeningDebt : l10n.debtOpeningCredit,
        _ => l10n.debtAdjustment,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    final padding = compact ? PosSpacing.l : PosSpacing.xl;
    final customer = (ref.watch(customersProvider).value ?? const [])
        .where((c) => c.id == customerId)
        .firstOrNull;
    if (customer == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final history =
        ref.watch(debtHistoryProvider(customerId)).value ?? const [];
    final purchases =
        ref.watch(purchasesProvider(customerId)).value ?? const [];
    final limit = customer.limitTiyin;
    final style = PosTypography.small.copyWith(color: p.textSecondary);

    Widget section(String title, List<Widget> children) => PosCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: PosTypography.h3.copyWith(color: p.text)),
          const SizedBox(height: PosSpacing.s),
          if (children.isEmpty)
            Text(l10n.customerHistoryEmpty, style: style)
          else
            ...children,
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        Row(
          children: [
            PosIconButton(
              key: const ValueKey('customer-back'),
              icon: Icons.arrow_back,
              tooltip: l10n.customerBack,
              onPressed: onClose,
            ),
            const SizedBox(width: PosSpacing.s),
            Expanded(
              child: Text(
                customer.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: (compact ? PosTypography.h3 : PosTypography.h2).copyWith(
                  color: p.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PosSpacing.m),
        PosCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Manfiy balans — do'kon mijozga qarzdor (avans): "Qarz: −50 000"
              // emas, "Mijoz haqi (avans): 50 000".
              Text(
                customer.balanceTiyin < 0
                    ? l10n.customerCredit
                    : l10n.customerDebt,
                style: style,
              ),
              PosMoneyText(
                key: const ValueKey('customer-balance'),
                amount: customer.balanceTiyin.abs(),
                currency: fmt.currency,
                size: PosMoneySize.total,
                tone: customer.balanceTiyin > 0
                    ? PosTone.danger
                    : customer.balanceTiyin < 0
                    ? PosTone.success
                    : null,
              ),
              const SizedBox(height: PosSpacing.xs),
              Text(
                [
                  if (customer.phone.isNotEmpty) customer.phone,
                  if (limit == null)
                    l10n.customerNoLimit
                  else
                    l10n.customerLimit(fmt.money(limit)),
                ].join(' · '),
                style: style,
              ),
              const SizedBox(height: PosSpacing.m),
              Wrap(
                spacing: PosSpacing.s,
                runSpacing: PosSpacing.s,
                children: [
                  if (customer.balanceTiyin > 0)
                    PosButton(
                      key: const ValueKey('customer-pay'),
                      label: l10n.customerPay,
                      icon: Icons.payments_outlined,
                      onPressed: () =>
                          unawaited(showDebtPaymentDialog(context, customer)),
                    ),
                  PosButton(
                    key: const ValueKey('customer-edit'),
                    label: l10n.customerEdit,
                    icon: Icons.edit_outlined,
                    variant: PosButtonVariant.secondary,
                    onPressed: () =>
                        unawaited(showCustomerEditDialog(context, customer.id)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PosSpacing.l),
        section(l10n.customerHistory, [
          for (final h in history)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        fmt.dateTime(h.at),
                        _type(l10n, h.type, h.amountTiyin),
                        ?h.saleNumber,
                        if (h.method == 'cash') l10n.payDebtCash,
                        if (h.method == 'card') l10n.payDebtCard,
                        ?h.byName,
                        if (h.note.isNotEmpty) h.note,
                      ].join(' · '),
                      style: PosTypography.small.copyWith(color: p.text),
                    ),
                  ),
                  PosMoneyText(
                    amount: h.amountTiyin,
                    currency: fmt.currency,
                    tone: h.amountTiyin > 0 ? PosTone.danger : PosTone.success,
                  ),
                ],
              ),
            ),
        ]),
        const SizedBox(height: PosSpacing.l),
        section(l10n.customerPurchases, [
          for (final s in purchases)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.number} · ${fmt.dateTime(s.soldAt)}',
                      style: PosTypography.small.copyWith(color: p.text),
                    ),
                  ),
                  PosMoneyText(amount: s.totalTiyin, currency: fmt.currency),
                ],
              ),
            ),
        ]),
      ],
    );
  }
}

/// Qarzni to'lash: summa ("To'liq"), naqd/karta. Joriy qarzdan ko'p emas.
Future<void> showDebtPaymentDialog(
  BuildContext context,
  CustomerEntry customer,
) => showPosDialog<void>(
  context: context,
  builder: (context) => _DebtPaymentDialog(customer: customer),
);

class _DebtPaymentDialog extends ConsumerStatefulWidget {
  const _DebtPaymentDialog({required this.customer});

  final CustomerEntry customer;

  @override
  ConsumerState<_DebtPaymentDialog> createState() => _DebtPaymentDialogState();
}

class _DebtPaymentDialogState extends ConsumerState<_DebtPaymentDialog> {
  int _amount = 0;
  String _method = 'cash';
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final balance = widget.customer.balanceTiyin;
    if (_amount <= 0 || _busy) return;
    if (_amount > balance) {
      setState(() => _error = l10n.payDebtTooMuch(fmt.money(balance)));
      return;
    }
    final user = ref.read(sessionProvider).user;
    if (user == null) return;
    // Bazadan to'g'ridan-to'g'ri: tinglovchisiz StreamProvider eskirgan
    // smenani qaytarishi mumkin (yopilgan smenaga naqd yozilmasin).
    final shiftId = (await openShiftNow(ref))?.id;
    if (!mounted) return;
    // Naqd smenasiz qabul qilinsa, hech bir Z-hisobotga tushmaydi (audit
    // CU-B4) — kassa puli hisobi buzilmasin.
    if (_method == 'cash' && shiftId == null) {
      setState(() => _error = l10n.payDebtNeedsShift);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(customerDirectoryProvider)
          .payDebt(
            customerId: widget.customer.id,
            amountTiyin: _amount,
            method: _method,
            by: user.id,
            shiftId: shiftId,
          );
      if (!mounted) return;
      showPosToast(
        context,
        message: l10n.payDebtDone(
          fmt.money(_amount),
          fmt.money(balance - _amount),
        ),
        tone: PosTone.success,
      );
      Navigator.of(context).pop();
    } on PaymentExceedsDebtException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.payDebtTooMuch(fmt.money(e.balanceTiyin));
        });
      }
    } on Object {
      // Kutilmagan xato — tugma qotmasin, foydalanuvchi bilsin (UI-P1-3).
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.actionFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final balance = widget.customer.balanceTiyin;
    final error = _error;
    return PosDialog(
      icon: Icons.payments_outlined,
      title: l10n.payDebtTitle,
      message:
          '${widget.customer.name} · ${l10n.customerDebt}: '
          '${fmt.money(balance)}',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (m, label) in [
                ('cash', l10n.payDebtCash),
                ('card', l10n.payDebtCard),
              ]) ...[
                if (m == 'card') const SizedBox(width: PosSpacing.s),
                Expanded(
                  child: PosButton(
                    key: ValueKey('debt-method-$m'),
                    label: label,
                    size: PosButtonSize.s,
                    expand: true,
                    variant: m == _method
                        ? PosButtonVariant.primary
                        : PosButtonVariant.secondary,
                    onPressed: () => setState(() => _method = m),
                  ),
                ),
              ],
              const SizedBox(width: PosSpacing.s),
              PosButton(
                key: const ValueKey('debt-full'),
                label: l10n.payDebtFull,
                size: PosButtonSize.s,
                variant: PosButtonVariant.ghost,
                onPressed: () => setState(() {
                  _amount = balance;
                  _error = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: PosSpacing.m),
          MoneyInput(
            valueTiyin: _amount,
            onChanged: (v) => setState(() {
              _amount = v;
              _error = null;
            }),
            onSubmit: () => unawaited(_submit()),
          ),
          if (error != null) ...[
            const SizedBox(height: PosSpacing.s),
            Text(
              error,
              style: PosTypography.bodyStrong.copyWith(color: p.dangerText),
            ),
          ],
        ],
      ),
      actions: [
        PosButton(
          label: l10n.actionCancel,
          variant: PosButtonVariant.secondary,
          shortcut: 'Esc',
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        PosButton(
          key: const ValueKey('debt-confirm'),
          label: l10n.payDebtConfirm,
          shortcut: 'Enter',
          icon: Icons.check,
          loading: _busy,
          onPressed: _amount > 0 && !_busy ? () => unawaited(_submit()) : null,
        ),
      ],
    );
  }
}

/// Tahrirlash: ism, telefon, izoh, qarz limiti (limit — ega/menejer).
Future<void> showCustomerEditDialog(BuildContext context, String customerId) =>
    showPosDialog<void>(
      context: context,
      builder: (context) => _CustomerEditDialog(customerId: customerId),
    );

class _CustomerEditDialog extends ConsumerStatefulWidget {
  const _CustomerEditDialog({required this.customerId});

  final String customerId;

  @override
  ConsumerState<_CustomerEditDialog> createState() =>
      _CustomerEditDialogState();
}

class _CustomerEditDialogState extends ConsumerState<_CustomerEditDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _limit = TextEditingController();
  CustomerDetails? _details;
  String? _nameError;
  String? _phoneError;
  bool _badLimit = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final d = await ref
        .read(customerDirectoryProvider)
        .details(widget.customerId);
    if (!mounted || d == null) return;
    setState(() {
      _details = d;
      _name.text = d.name;
      _phone.text = d.phone;
      _note.text = d.note;
      _limit.text = d.limitTiyin == null ? '' : formatMoneyInput(d.limitTiyin!);
      // 0 — "nasiya berilmaydi": bo'sh emas.
      if (d.limitTiyin == 0) _limit.text = '0';
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _note, _limit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final details = _details;
    if (details == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = l10n.fieldRequired);
      return;
    }
    if (normalizePhone(_phone.text) == null) {
      setState(() => _phoneError = l10n.phoneInvalid);
      return;
    }
    final text = _limit.text.trim();
    final limit = text.isEmpty ? null : parseMoneyTiyin(text);
    if (text.isNotEmpty && limit == null) {
      setState(() => _badLimit = true);
      return;
    }
    final changeLimit = limit != details.limitTiyin;
    final user = ref.read(sessionProvider).user;
    if (user == null) return;
    var by = user.id;
    if (changeLimit && !DiscountPolicy.canApprove(user.role)) {
      final approver = await requestManagerApproval(
        context,
        reason: l10n.customerLimitNeedsApproval,
      );
      if (approver == null || !mounted) return;
      by = approver;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(customerDirectoryProvider)
          .update(
            id: details.id,
            name: _name.text,
            phone: _phone.text,
            note: _note.text,
            by: by,
            changeLimit: changeLimit,
            limitTiyin: limit,
          );
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        showPosToast(context, message: l10n.actionFailed, tone: PosTone.danger);
      }
      return;
    }
    if (!mounted) return;
    showPosToast(context, message: l10n.customerSaved, tone: PosTone.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PosDialog(
      icon: Icons.person_outline,
      title: l10n.customerEdit,
      content: _details == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosTextField(
                  key: const ValueKey('customer-name'),
                  controller: _name,
                  label: l10n.payCustomerName,
                  errorText: _nameError,
                  onChanged: (_) => setState(() => _nameError = null),
                ),
                const SizedBox(height: PosSpacing.s),
                PosTextField(
                  key: const ValueKey('customer-phone'),
                  controller: _phone,
                  label: l10n.payCustomerPhone,
                  keyboardType: TextInputType.phone,
                  errorText: _phoneError,
                  onChanged: (_) => setState(() => _phoneError = null),
                ),
                const SizedBox(height: PosSpacing.s),
                PosTextField(
                  key: const ValueKey('customer-note'),
                  controller: _note,
                  label: l10n.customerNote,
                ),
                const SizedBox(height: PosSpacing.s),
                PosTextField(
                  key: const ValueKey('customer-limit'),
                  controller: _limit,
                  label: l10n.customerLimitField,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s,.]')),
                  ],
                  errorText: _badLimit ? l10n.productErrPrice : null,
                  onChanged: (_) => setState(() => _badLimit = false),
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
          key: const ValueKey('customer-save'),
          label: l10n.actionSave,
          loading: _busy,
          onPressed: () => unawaited(_save()),
        ),
      ],
    );
  }
}
