import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/cart/cart_controller.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Chek tablari: "Chek 1 · Chek 2 · +" (kechiktirilgan cheklar, ≤ 5).
class CartTabs extends StatelessWidget {
  const CartTabs({
    required this.state,
    required this.onSelect,
    required this.onNew,
    this.compact = false,
    this.trailing,
    super.key,
  });

  final CartState state;
  final ValueChanged<int> onSelect;
  final VoidCallback onNew;

  /// Telefon: tezkor tugma yorliqlari yo'q.
  final bool compact;

  /// O'ng chetda (telefonda — smena tugmasi).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, cart) in state.carts.indexed) ...[
            PosButton(
              label: l10n.posCartTab(cart.slot + 1),
              size: PosButtonSize.s,
              variant: i == state.active
                  ? PosButtonVariant.primary
                  : PosButtonVariant.secondary,
              onPressed: () => onSelect(i),
            ),
            const SizedBox(width: PosSpacing.xs),
          ],
          PosButton(
            label: l10n.posNewCart,
            icon: Icons.add,
            size: PosButtonSize.s,
            variant: PosButtonVariant.ghost,
            shortcut: compact ? null : 'F6',
            onPressed: state.canAddCart ? onNew : null,
          ),
        ],
      ),
    );
    if (trailing == null) return tabs;
    return Row(
      children: [
        Expanded(child: tabs),
        const SizedBox(width: PosSpacing.s),
        trailing!,
      ],
    );
  }
}

/// Savat qatorlari ro'yxati: qo'shilgan qatorga aylanadi va uni yondiradi.
class CartLines extends StatefulWidget {
  const CartLines({
    required this.state,
    required this.onSelect,
    required this.onQtyChanged,
    required this.onQtyTap,
    required this.onRemove,
    this.swipeToRemove = false,
    super.key,
  });

  final CartState state;
  final ValueChanged<String> onSelect;
  final void Function(CartLine line, int qtyMilli) onQtyChanged;
  final ValueChanged<CartLine> onQtyTap;
  final ValueChanged<CartLine> onRemove;

  /// Telefon: chapga surib o'chirish; aks holda — o'chirish tugmasi.
  final bool swipeToRemove;

  @override
  State<CartLines> createState() => _CartLinesState();
}

class _CartLinesState extends State<CartLines> {
  final Map<String, GlobalKey> _keys = {};

  @override
  void didUpdateWidget(CartLines oldWidget) {
    super.didUpdateWidget(oldWidget);
    final added = widget.state.lastAdded;
    if (added != null && added.seq != oldWidget.state.lastAdded?.seq) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _keys[added.lineId]?.currentContext;
        if (context != null && context.mounted) {
          unawaited(
            Scrollable.ensureVisible(
              context,
              duration: PosMotion.overlay,
              curve: PosMotion.curve,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lines = widget.state.cart.lines;
    final ids = {for (final l in lines) l.id};
    _keys.removeWhere((id, _) => !ids.contains(id));
    final added = widget.state.lastAdded;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
      itemCount: lines.length,
      separatorBuilder: (_, _) => const SizedBox(height: PosSpacing.xs),
      itemBuilder: (context, i) {
        final line = lines[i];
        final tile = CartLineTile(
          key: _keys.putIfAbsent(line.id, GlobalKey.new),
          line: line,
          selected: line.id == widget.state.selectedLineId,
          flashSeq: added?.lineId == line.id ? added!.seq : null,
          showRemove: !widget.swipeToRemove,
          onTap: () => widget.onSelect(line.id),
          onQtyChanged: (v) => widget.onQtyChanged(line, v),
          onQtyTap: () => widget.onQtyTap(line),
          onRemove: () => widget.onRemove(line),
        );
        if (!widget.swipeToRemove) return tile;
        return Dismissible(
          key: ValueKey('dismiss-${line.id}'),
          direction: DismissDirection.endToStart,
          background: _RemoveBackground(label: l10n.actionDelete),
          onDismissed: (_) => widget.onRemove(line),
          child: tile,
        );
      },
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: PosSpacing.l),
      decoration: BoxDecoration(
        color: p.danger,
        borderRadius: PosRadius.controlAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: p.onDanger),
          const SizedBox(width: PosSpacing.xs),
          Text(
            label,
            style: PosTypography.bodyStrong.copyWith(color: p.onDanger),
          ),
        ],
      ),
    );
  }
}

/// Savat qatori: nom va jami; ostida narx × miqdor, chegirma, stepper.
class CartLineTile extends StatefulWidget {
  const CartLineTile({
    required this.line,
    required this.selected,
    required this.onTap,
    required this.onQtyChanged,
    required this.onQtyTap,
    required this.onRemove,
    this.flashSeq,
    this.showRemove = true,
    super.key,
  });

  final CartLine line;
  final bool selected;

  /// O'zgarsa — qator qisqa yonadi (skanerdan qo'shildi).
  final int? flashSeq;
  final bool showRemove;
  final VoidCallback onTap;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onQtyTap;
  final VoidCallback onRemove;

  @override
  State<CartLineTile> createState() => _CartLineTileState();
}

class _CartLineTileState extends State<CartLineTile> {
  static const double _inlineControlsMinWidth = 400;

  bool _flash = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.flashSeq != null) _startFlash();
  }

  @override
  void didUpdateWidget(CartLineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashSeq != null && widget.flashSeq != oldWidget.flashSeq) {
      _startFlash();
    }
  }

  void _startFlash() {
    _timer?.cancel();
    _flash = true;
    _timer = Timer(PosMotion.overlay, () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final line = widget.line;
    final unit = UnitCode.fromCode(line.unit);
    final weighted = line.weighted || unit.fractional;
    final background = _flash
        ? p.successSoft
        : (widget.selected ? p.primarySoft : p.surface);

    return Semantics(
      selected: widget.selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: PosRadius.controlAll,
          child: AnimatedContainer(
            duration: PosMotion.overlay,
            curve: PosMotion.curve,
            padding: const EdgeInsets.fromLTRB(
              PosSpacing.m,
              PosSpacing.s,
              PosSpacing.xs,
              PosSpacing.s,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: PosRadius.controlAll,
              border: Border.all(
                color: widget.selected ? p.focus : p.border,
                width: widget.selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        line.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PosTypography.bodyStrong.copyWith(color: p.text),
                      ),
                    ),
                    const SizedBox(width: PosSpacing.s),
                    Padding(
                      padding: const EdgeInsets.only(right: PosSpacing.s),
                      child: PosMoneyText(
                        amount: line.totalTiyin,
                        currency: fmt.currency,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PosSpacing.xs),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final info = Wrap(
                      spacing: PosSpacing.s,
                      runSpacing: PosSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${fmt.money(line.priceTiyin)} / ${unit.label(l10n)}',
                          style: PosTypography.small.copyWith(
                            color: p.textSecondary,
                            fontFeatures: PosTypography.tabular,
                          ),
                        ),
                        if (line.discountTiyin > 0)
                          PosBadge(
                            label: fmt.money(-line.discountTiyin),
                            tone: PosTone.success,
                            icon: Icons.percent,
                          ),
                      ],
                    );
                    final controls = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PosQtyStepper(
                          valueMilli: line.qtyMilli,
                          weighted: weighted,
                          unit: unit.label(l10n),
                          minMilli: weighted ? 1 : 1000,
                          stepMilli: weighted ? 100 : 1000,
                          decrementTooltip: l10n.actionDecrease,
                          incrementTooltip: l10n.actionIncrease,
                          onChanged: widget.onQtyChanged,
                          onValueTap: widget.onQtyTap,
                        ),
                        if (widget.showRemove)
                          PosIconButton(
                            icon: Icons.delete_outline,
                            tooltip: l10n.actionDelete,
                            onPressed: widget.onRemove,
                          ),
                      ],
                    );
                    // Tor savat (planshet): boshqaruv alohida qatorda.
                    if (constraints.maxWidth < _inlineControlsMinWidth) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          info,
                          const SizedBox(height: PosSpacing.xs),
                          Align(
                            alignment: Alignment.centerRight,
                            child: controls,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: info),
                        controls,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Savat osti: mijoz (F4), chegirma (F3), tovarlar soni, JAMI (eng katta
/// matn), To'lash.
class CartSummary extends StatelessWidget {
  const CartSummary({
    required this.cart,
    required this.onDiscount,
    required this.onPay,
    required this.payEnabled,
    this.customerName,
    this.onCustomer,
    this.onRemoveCustomer,
    this.compact = false,
    super.key,
  });

  final Cart cart;
  final VoidCallback onDiscount;
  final VoidCallback onPay;
  final bool payEnabled;

  /// Chek mijozi ismi (`null` — tanlanmagan).
  final String? customerName;
  final VoidCallback? onCustomer;
  final VoidCallback? onRemoveCustomer;

  /// Telefon: yopishqoq panel — faqat JAMI va To'lash.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final discounts = cart.allDiscountsTiyin;

    final total = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.totalLabel,
                style: PosTypography.bodyStrong.copyWith(
                  color: p.textSecondary,
                ),
              ),
              Text(
                l10n.posItemsCount(cart.itemCount),
                style: PosTypography.small.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
        Flexible(
          flex: 3,
          child: PosMoneyText(
            amount: cart.totalTiyin,
            currency: fmt.currency,
            size: PosMoneySize.total,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );

    final pay = PosButton(
      label: l10n.actionPay,
      icon: Icons.payments_outlined,
      size: compact ? PosButtonSize.m : PosButtonSize.xl,
      shortcut: compact ? null : 'F12',
      expand: true,
      onPressed: payEnabled && !cart.isEmpty ? onPay : null,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          total,
          const SizedBox(height: PosSpacing.s),
          pay,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onCustomer != null)
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PosButton(
                    key: const ValueKey('cart-customer'),
                    label: customerName ?? l10n.posCustomer,
                    icon: Icons.person_outline,
                    size: PosButtonSize.s,
                    variant: PosButtonVariant.ghost,
                    shortcut: 'F4',
                    onPressed: onCustomer,
                  ),
                ),
              ),
              if (customerName != null && onRemoveCustomer != null)
                PosIconButton(
                  icon: Icons.close,
                  tooltip: l10n.posCustomerRemove,
                  onPressed: onRemoveCustomer,
                ),
            ],
          ),
        if (discounts > 0)
          _SummaryRow(
            label: l10n.posSubtotal,
            amount: cart.totalTiyin + discounts,
          ),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: PosButton(
                  label: l10n.posDiscount,
                  icon: Icons.percent,
                  size: PosButtonSize.s,
                  variant: PosButtonVariant.ghost,
                  shortcut: 'F3',
                  onPressed: cart.isEmpty ? null : onDiscount,
                ),
              ),
            ),
            if (discounts > 0)
              PosMoneyText(
                amount: -discounts,
                currency: fmt.currency,
                tone: PosTone.success,
              ),
          ],
        ),
        const SizedBox(height: PosSpacing.s),
        total,
        const SizedBox(height: PosSpacing.m),
        pay,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: PosTypography.body.copyWith(color: p.textSecondary),
            ),
          ),
          PosMoneyText(amount: amount, currency: context.fmt.currency),
        ],
      ),
    );
  }
}
