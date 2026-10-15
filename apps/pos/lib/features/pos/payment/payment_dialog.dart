import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/scanner/scanner_settings.dart';
import 'package:pos_app/core/barcode/scanner_service.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/common/money_input.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/payment/checkout.dart';
import 'package:pos_app/features/pos/payment/customer_picker.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// F12: to'lov oynasi (`docs/specs/pos-screen.md`, 3-qadam). Savdo shu
/// oynada yoziladi (`Checkout` — bitta tranzaksiya); natija — yakunlangan
/// savdo yoki `null` (bekor qilindi, savat joyida).
Future<CheckoutResult?> showPaymentDialog(
  BuildContext context, {
  required Cart cart,
  PayMode mode = PayMode.cash,
}) => showPosDialog<CheckoutResult>(
  context: context,
  maxWidth: PaymentDialog.maxWidth,
  builder: (context) => PaymentDialog(cart: cart, initialMode: mode),
);

/// Aralash to'lovda tahrirlanayotgan qism (qolgani — naqd).
enum _Part { card, debt }

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({
    required this.cart,
    this.initialMode = PayMode.cash,
    super.key,
  });

  static const double maxWidth = 560;

  final Cart cart;

  /// Kassada F11 (Nasiya) — oyna nasiyada ochiladi.
  final PayMode initialMode;

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  late PaymentDraft _draft = PaymentDraft(
    totalTiyin: widget.cart.totalTiyin,
    mode: widget.initialMode,
    customerId: widget.cart.customerId,
  );

  /// Oyna ichida ham kassadagi kabi: F9 naqd, F10 karta, F11 nasiya.
  static final Map<LogicalKeyboardKey, PayMode> _modeKeys = {
    LogicalKeyboardKey.f9: PayMode.cash,
    LogicalKeyboardKey.f10: PayMode.card,
    LogicalKeyboardKey.f11: PayMode.debt,
  };
  _Part _part = _Part.card;

  /// Oyna klaviaturasi (Enter, Backspace). Matn maydoni yopilgach fokus
  /// shu yerga qaytariladi — aks holda Enter hech qayerga yetmaydi.
  final _focus = FocusNode(debugLabel: 'payment');

  /// Nasiya mijozi tanlanmoqda (tanlangan bo'lsa ham "Boshqa mijoz").
  bool _picking = false;

  /// Telefonda ekran klaviaturasi summaga bosilganda ochiladi (tez summalar
  /// bilan qaytim va "Yakunlash" bir ekranda ko'rinsin).
  bool? _keypadOpen;
  bool _busy = false;

  /// Menejer oynasi ochiq — PIN raqamlari skaner buferiga tushmasin.
  bool _approving = false;

  /// Limitdan oshishga ruxsat: shu mijoz va shu summa uchun.
  ({String customerId, int amount, String by})? _approval;

  /// Skaner Enter'i oynaga ham yetib keladi — u savdoni yakunlamasin.
  bool _swallowEnter = false;

  ({String text, PosTone tone})? _notice;
  Timer? _noticeTimer;

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  // ---- Holat ------------------------------------------------------------

  void _update(PaymentDraft draft) => setState(() {
    _draft = draft;
    if (_notice?.tone != PosTone.danger) _notice = null;
  });

  void _setMode(PayMode mode) {
    if (mode == _draft.mode) return;
    _update(
      _draft.copyWith(mode: mode, exact: true, cardTiyin: 0, debtTiyin: 0),
    );
    setState(() {
      _part = _Part.card;
      _picking = false;
    });
    _focus.requestFocus();
  }

  void _setPart(_Part part) {
    setState(() => _part = part);
    _focus.requestFocus();
  }

  /// Klaviaturadan tahrirlanadigan summa (karta/nasiyada — yo'q).
  int? get _editedValue => switch (_draft.mode) {
    PayMode.cash => _draft.receivedTiyin ?? 0,
    PayMode.mixed => _part == _Part.card ? _draft.cardTiyin : _draft.debtTiyin,
    _ => null,
  };

  void _setEdited(int tiyin) => _update(switch (_draft.mode) {
    PayMode.cash => _draft.copyWith(receivedTiyin: tiyin),
    PayMode.mixed when _part == _Part.card => _draft.copyWith(cardTiyin: tiyin),
    PayMode.mixed => _draft.copyWith(debtTiyin: tiyin),
    _ => _draft,
  });

  void _selectCustomer(CustomerEntry customer) {
    _update(_draft.copyWith(customerId: customer.id));
    setState(() => _picking = false);
    _focus.requestFocus();
  }

  void _showNotice(String text, PosTone tone) {
    _noticeTimer?.cancel();
    setState(() => _notice = (text: text, tone: tone));
    _noticeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  // ---- Klaviatura va skaner ---------------------------------------------

  void _onScan(ScanEvent event) {
    _swallowEnter = true;
    scheduleMicrotask(() => _swallowEnter = false);
    unawaited(ref.read(scanSignalProvider).notFound());
    _showNotice(AppLocalizations.of(context).payScanBlocked, PosTone.warning);
  }

  /// Matn maydonidan tashqarida yozilgan raqamlar — summaga.
  void _onTyping(String text) {
    final value = _editedValue;
    if (value == null) return;
    final base = _draft.mode == PayMode.cash && _draft.receivedTiyin == null
        ? 0
        : value;
    final next = MoneyInput.append(base, text);
    if (next != value || base != value) _setEdited(next);
  }

  static bool get _inTextField =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>() !=
      null;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _inTextField) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final mode = _modeKeys[key];
    if (mode != null) {
      _setMode(mode);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_swallowEnter) {
        _swallowEnter = false;
      } else {
        unawaited(_submit());
      }
      return KeyEventResult.handled;
    }
    final value = _editedValue;
    if (key == LogicalKeyboardKey.backspace && value != null) {
      final exact = _draft.mode == PayMode.cash && _draft.receivedTiyin == null;
      _setEdited(exact ? 0 : (value ~/ 1000) * 100);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---- Yakunlash --------------------------------------------------------

  String _problemText(AppLocalizations l10n, PaymentProblem problem) =>
      switch (problem) {
        PaymentProblem.notEnoughCash => l10n.payShort,
        PaymentProblem.partsExceedTotal => l10n.payPartsExceed,
        PaymentProblem.customerRequired => l10n.payChooseCustomer,
      };

  CustomerEntry? _customer(List<CustomerEntry> all) {
    final id = _draft.customerId;
    if (id == null) return null;
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy || _approving) return;
    final l10n = AppLocalizations.of(context);
    final problem = _draft.problem;
    if (problem != null) {
      _showNotice(_problemText(l10n, problem), PosTone.warning);
      return;
    }
    if (!_draft.isValid) return;

    final draft = _draft;
    String? approvedBy;
    if (draft.debtPart > 0) {
      final customer = _customer(
        ref.read(customersProvider).value ?? const [],
      );
      if (customer != null && !customer.allowsDebt(draft.debtPart)) {
        final approval = _approval;
        if (approval != null &&
            approval.customerId == customer.id &&
            approval.amount == draft.debtPart) {
          approvedBy = approval.by;
        } else {
          setState(() => _approving = true);
          approvedBy = await requestManagerApproval(
            context,
            reason: l10n.payLimitExceeded,
          );
          if (!mounted) return;
          setState(() => _approving = false);
          if (approvedBy == null) return;
          _approval = (
            customerId: customer.id,
            amount: draft.debtPart,
            by: approvedBy,
          );
        }
      }
    }

    setState(() => _busy = true);
    try {
      final result = await checkoutNow(
        ref,
        cart: widget.cart,
        payment: draft,
        debtApprovedBy: approvedBy,
      );
      if (!mounted) return;
      if (result == null) {
        setState(() => _busy = false);
        _showNotice(l10n.payFailed, PosTone.danger);
        return;
      }
      Navigator.of(context).pop(result);
    } on Exception {
      if (!mounted) return;
      setState(() => _busy = false);
      _showNotice(l10n.payFailed, PosTone.danger);
    }
  }

  // ---- Maket ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final customers =
        ref.watch(customersProvider).value ?? const <CustomerEntry>[];
    final notice = _notice;
    final compact = PosWindowSize.of(context).isCompact;

    return ScanListener(
      enabled: !_approving,
      onScan: _onScan,
      onTyping: _onTyping,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: PosDialog(
          title: l10n.payTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.totalLabel,
                      style: PosTypography.bodyStrong.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                  PosMoneyText(
                    amount: _draft.totalTiyin,
                    currency: fmt.currency,
                    size: PosMoneySize.large,
                  ),
                ],
              ),
              const SizedBox(height: PosSpacing.m),
              _Grid(
                children: [
                  for (final (mode, label, key) in [
                    (PayMode.cash, l10n.payCash, 'F9'),
                    (PayMode.card, l10n.payCard, 'F10'),
                    (PayMode.debt, l10n.payDebt, 'F11'),
                    (PayMode.mixed, l10n.payMixed, null),
                  ])
                    PosButton(
                      key: ValueKey('pay-mode-${mode.name}'),
                      label: label,
                      size: PosButtonSize.s,
                      shortcut: compact ? null : key,
                      expand: true,
                      variant: mode == _draft.mode
                          ? PosButtonVariant.primary
                          : PosButtonVariant.secondary,
                      onPressed: () => _setMode(mode),
                    ),
                ],
              ),
              const SizedBox(height: PosSpacing.l),
              ...switch (_draft.mode) {
                PayMode.cash => _cash(l10n),
                PayMode.card => _card(l10n),
                PayMode.debt => _debt(l10n, customers),
                PayMode.mixed => _mixed(l10n, customers),
              },
              if (notice != null) ...[
                const SizedBox(height: PosSpacing.m),
                _Notice(text: notice.text, tone: notice.tone),
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
              key: const ValueKey('pay-complete'),
              label: l10n.payComplete,
              shortcut: 'Enter',
              icon: Icons.check,
              loading: _busy,
              onPressed: _draft.isValid && !_busy
                  ? () => unawaited(_submit())
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Telefonda naqdda yopiq (tez summalar bor), aralashda — ochiq.
  bool get _keypad =>
      _keypadOpen ??
      (_draft.mode != PayMode.cash || !PosWindowSize.of(context).isCompact);

  MoneyInput _moneyInput({required Key key, bool pristine = false}) =>
      MoneyInput(
        key: key,
        valueTiyin: pristine ? _draft.cashDue : (_editedValue ?? 0),
        pristine: pristine,
        // Raqamlar skaner xizmati orqali (`_onTyping`), Backspace/Enter —
        // oynaning o'zida.
        hardwareDigits: false,
        autofocus: false,
        showKeypad: _keypad,
        onDisplayTap: () => setState(() => _keypadOpen = !_keypad),
        onChanged: _setEdited,
      );

  List<Widget> _cash(AppLocalizations l10n) {
    final fmt = context.fmt;
    final exact = _draft.receivedTiyin == null;
    final due = _draft.cashDue;
    return [
      _Grid(
        children: [
          PosButton(
            label: l10n.payExact,
            size: PosButtonSize.s,
            expand: true,
            variant: exact
                ? PosButtonVariant.primary
                : PosButtonVariant.secondary,
            onPressed: () => _update(_draft.copyWith(exact: true)),
          ),
          for (final som in PaymentDraft.quickCashSom)
            PosButton(
              label: fmt.moneyAmount(som * 100),
              size: PosButtonSize.s,
              expand: true,
              variant: !exact && _draft.receivedTiyin == som * 100
                  ? PosButtonVariant.primary
                  : PosButtonVariant.secondary,
              onPressed: som * 100 < due
                  ? null
                  : () => _update(_draft.copyWith(receivedTiyin: som * 100)),
            ),
        ],
      ),
      const SizedBox(height: PosSpacing.m),
      _Label(l10n.payReceived),
      const SizedBox(height: PosSpacing.xs),
      _moneyInput(key: const ValueKey('pay-received'), pristine: exact),
      const SizedBox(height: PosSpacing.m),
      _cashResult(l10n),
    ];
  }

  /// Qaytim — katta yashil; yetmasa — qizil farq.
  Widget _cashResult(AppLocalizations l10n) {
    final short = _draft.cashDue - _draft.received;
    final (label, amount, tone) = short > 0
        ? (l10n.payShort, short, PosTone.danger)
        : (l10n.changeLabel, _draft.changeTiyin, PosTone.success);
    return Row(
      key: const ValueKey('pay-change'),
      children: [
        Expanded(child: _Label(label, strong: true)),
        PosMoneyText(
          amount: amount,
          currency: context.fmt.currency,
          size: PosMoneySize.total,
          tone: amount > 0 ? tone : null,
        ),
      ],
    );
  }

  List<Widget> _card(AppLocalizations l10n) {
    final p = PosPalette.of(context);
    return [
      Icon(Icons.credit_card, size: PosSizes.iconXl, color: p.primaryText),
      const SizedBox(height: PosSpacing.s),
      Text(
        l10n.payCardHint,
        textAlign: TextAlign.center,
        style: PosTypography.body.copyWith(color: p.textSecondary),
      ),
    ];
  }

  List<Widget> _debt(AppLocalizations l10n, List<CustomerEntry> customers) => [
    _customerSection(l10n, customers),
  ];

  Widget _customerSection(
    AppLocalizations l10n,
    List<CustomerEntry> customers,
  ) {
    final customer = _customer(customers);
    if (customer == null || _picking) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Label(l10n.payChooseCustomer),
          const SizedBox(height: PosSpacing.s),
          CustomerPicker(
            selectedId: _draft.customerId,
            onSelected: _selectCustomer,
            listHeight: 200,
          ),
        ],
      );
    }
    final overLimit = !customer.allowsDebt(_draft.debtPart);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomerTile(
          customer: customer,
          selected: true,
          trailing: PosButton(
            label: l10n.payChangeCustomer,
            size: PosButtonSize.s,
            variant: PosButtonVariant.ghost,
            onPressed: () => setState(() => _picking = true),
          ),
        ),
        if (overLimit) ...[
          const SizedBox(height: PosSpacing.s),
          _Notice(text: l10n.payLimitExceeded, tone: PosTone.warning),
        ],
      ],
    );
  }

  List<Widget> _mixed(AppLocalizations l10n, List<CustomerEntry> customers) {
    final fmt = context.fmt;
    return [
      _PartRow(
        key: const ValueKey('pay-part-card'),
        label: l10n.payCard,
        amount: _draft.cardTiyin,
        active: _part == _Part.card,
        onTap: () => _setPart(_Part.card),
      ),
      const SizedBox(height: PosSpacing.s),
      _PartRow(
        key: const ValueKey('pay-part-debt'),
        label: l10n.payDebt,
        amount: _draft.debtTiyin,
        active: _part == _Part.debt,
        onTap: () => _setPart(_Part.debt),
      ),
      const SizedBox(height: PosSpacing.s),
      Row(
        children: [
          Expanded(child: _Label(l10n.payCashRest, strong: true)),
          PosMoneyText(
            amount: _draft.cashDue,
            currency: fmt.currency,
            size: PosMoneySize.medium,
            tone: _draft.cashDue < 0 ? PosTone.danger : null,
          ),
        ],
      ),
      const SizedBox(height: PosSpacing.m),
      _moneyInput(key: ValueKey('pay-mixed-${_part.name}')),
      if (_draft.debtTiyin > 0) ...[
        const SizedBox(height: PosSpacing.m),
        _customerSection(l10n, customers),
      ],
    ];
  }
}

/// Tugmalar to'ri: keng oynada bir qatorda, tor (telefon) — ikki ustun.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  static const double _oneRowMinWidth = 420;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= _oneRowMinWidth
          ? children.length
          : 2;
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += columns) {
        if (rows.isNotEmpty) rows.add(const SizedBox(height: PosSpacing.s));
        rows.add(
          Row(
            children: [
              for (var j = i; j < i + columns; j++) ...[
                if (j > i) const SizedBox(width: PosSpacing.s),
                Expanded(
                  child: j < children.length
                      ? children[j]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      }
      return Column(mainAxisSize: MainAxisSize.min, children: rows);
    },
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Text(
      text,
      style: strong
          ? PosTypography.bodyStrong.copyWith(color: p.text)
          : PosTypography.small.copyWith(color: p.textSecondary),
    );
  }
}

/// Aralash to'lov qismi: bosilsa — klaviatura shu summani tahrirlaydi.
class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.label,
    required this.amount,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final int amount;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? p.primarySoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
          side: BorderSide(
            color: active ? p.focus : p.border,
            width: active ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          borderRadius: PosRadius.controlAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PosSizes.cashierMain),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PosSpacing.l),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: PosTypography.bodyStrong.copyWith(
                        color: active ? p.onPrimarySoft : p.text,
                      ),
                    ),
                  ),
                  PosMoneyText(
                    amount: amount,
                    currency: context.fmt.currency,
                    size: PosMoneySize.medium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Oyna ichidagi xabar (oyna ostidagi toast ko'rinmaydi).
class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.tone});

  final String text;
  final PosTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = PosPalette.of(context).tone(tone);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.soft,
          borderRadius: PosRadius.controlAll,
        ),
        child: Padding(
          padding: const EdgeInsets.all(PosSpacing.m),
          child: Row(
            children: [
              Icon(
                PosToast.iconFor(tone),
                size: PosSizes.iconM,
                color: colors.onSoft,
              ),
              const SizedBox(width: PosSpacing.s),
              Expanded(
                child: Text(
                  text,
                  style: PosTypography.body.copyWith(color: colors.onSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
