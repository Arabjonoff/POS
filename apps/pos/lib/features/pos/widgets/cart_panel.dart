import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_app/core/format/app_format.dart';
import 'package:pos_app/core/format/unit_code.dart';
import 'package:pos_app/core/money/money.dart';
import 'package:pos_app/data/customers/customer_directory.dart';
import 'package:pos_app/features/pos/cart/cart.dart';
import 'package:pos_app/features/pos/cart/cart_controller.dart';
import 'package:pos_app/features/pos/payment/payment_draft.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Chek tablari: "Chek 1 · Chek 2 (3) · + Yangi (F6)" — kechiktirilgan
/// chekda pozitsiyalar soni (≤ 5 chek).
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
            _CartTab(
              label: l10n.posCartTab(cart.slot + 1),
              count: cart.lines.length,
              active: i == state.active,
              onTap: () => onSelect(i),
            ),
            const SizedBox(width: PosSpacing.s),
          ],
          // Telefonda — faqat ikon: yonidagi tugmalarga joy qolsin.
          if (compact)
            PosIconButton(
              icon: Icons.add,
              tooltip: l10n.posNewCart,
              onPressed: state.canAddCart ? onNew : null,
            )
          else
            PosButton(
              label: l10n.posNewCart,
              icon: Icons.add,
              size: PosButtonSize.s,
              variant: PosButtonVariant.ghost,
              shortcut: 'F6',
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

class _CartTab extends StatelessWidget {
  const _CartTab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    // Kechiktirilgan chekda nechta pozitsiya borligi ko'rinib tursin.
    final showCount = !active && count > 0;
    return Semantics(
      button: true,
      selected: active,
      label: count > 0 ? l10n.posCartTabItems(label, count) : label,
      excludeSemantics: true,
      child: Material(
        color: active ? p.primary : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
          side: active ? BorderSide.none : BorderSide(color: p.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: p.text.withValues(alpha: 0.04),
          child: Container(
            height: PosSizes.touchMin,
            padding: const EdgeInsets.symmetric(horizontal: PosSpacing.l),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: PosTypography.bodyStrong.copyWith(
                    color: active ? p.onPrimary : p.text,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (showCount) ...[
                  const SizedBox(width: PosSpacing.s),
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: PosSpacing.xs + 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: PosRadius.pillAll,
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: PosTypography.caption.copyWith(
                        color: p.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: PosTypography.tabular,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chek qatorlari: ustun sarlavhasi (desktop) va ro'yxat; qo'shilgan qatorga
/// aylanadi va uni 1 s yashil qiladi.
class CartLines extends StatefulWidget {
  const CartLines({
    required this.state,
    required this.onSelect,
    required this.onQtyTap,
    required this.onRemove,
    this.swipeToRemove = false,
    super.key,
  });

  final CartState state;
  final ValueChanged<String> onSelect;
  final ValueChanged<CartLine> onQtyTap;
  final ValueChanged<CartLine> onRemove;

  /// Telefon: chapga surib o'chirish (o'chirish tugmasi va sarlavha yo'q).
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = CartRowLayout.of(
          constraints.maxWidth,
          showRemove: !widget.swipeToRemove,
        );
        final list = ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
          itemCount: lines.length,
          separatorBuilder: (_, _) => const SizedBox(height: PosSpacing.xs),
          itemBuilder: (context, i) {
            final line = lines[i];
            final tile = CartLineTile(
              key: _keys.putIfAbsent(line.id, GlobalKey.new),
              line: line,
              number: i + 1,
              layout: layout,
              selected: line.id == widget.state.selectedLineId,
              flashSeq: added?.lineId == line.id ? added!.seq : null,
              onTap: () => widget.onSelect(line.id),
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
        if (widget.swipeToRemove) return list;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LinesHeader(layout: layout),
            Expanded(child: list),
          ],
        );
      },
    );
  }
}

/// Chek qatori ustunlari kengligi (sarlavha va qatorlar bir xil).
class CartRowLayout {
  const CartRowLayout({
    required this.showNumber,
    required this.qtyWidth,
    required this.sumWidth,
    required this.showRemove,
  });

  /// Tor savatda (planshet, ~420 dp) № ustuni yo'q — nomga joy.
  factory CartRowLayout.of(double width, {required bool showRemove}) {
    final wide = width >= 460;
    return CartRowLayout(
      showNumber: wide,
      qtyWidth: wide ? 96 : 84,
      sumWidth: wide ? 104 : 92,
      showRemove: showRemove,
    );
  }

  final bool showNumber;
  final double qtyWidth;
  final double sumWidth;
  final bool showRemove;

  static const double numberWidth = 24;
  static const double gap = PosSpacing.m;
}

class _LinesHeader extends StatelessWidget {
  const _LinesHeader({required this.layout});

  final CartRowLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = PosTypography.caption.copyWith(
      color: PosPalette.of(context).textMuted,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PosSpacing.m,
          0,
          PosSpacing.xs,
          PosSpacing.xs,
        ),
        child: Row(
          children: [
            if (layout.showNumber) ...[
              SizedBox(
                width: CartRowLayout.numberWidth,
                child: Text(l10n.posColNo, style: style),
              ),
              const SizedBox(width: CartRowLayout.gap),
            ],
            Expanded(child: Text(l10n.posColName.toUpperCase(), style: style)),
            const SizedBox(width: CartRowLayout.gap),
            SizedBox(
              width: layout.qtyWidth,
              child: Text(
                l10n.posColQty.toUpperCase(),
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
            const SizedBox(width: CartRowLayout.gap),
            SizedBox(
              width: layout.sumWidth,
              child: Text(
                l10n.posColSum.toUpperCase(),
                textAlign: TextAlign.right,
                style: style,
              ),
            ),
            if (layout.showRemove)
              const SizedBox(width: PosSizes.touchMin + PosSpacing.xs),
          ],
        ),
      ),
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

/// Chek qatori: № | nom va birlik narxi | miqdor tugmasi | summa | o'chirish.
/// Tanlangan — ko'k chegara; skanerdan qo'shilgan — 1 s yashil fon.
class CartLineTile extends StatefulWidget {
  const CartLineTile({
    required this.line,
    required this.number,
    required this.layout,
    required this.selected,
    required this.onTap,
    required this.onQtyTap,
    required this.onRemove,
    this.flashSeq,
    super.key,
  });

  /// Yashil fon qancha turadi (keyin ≤ 200 ms da so'nadi).
  static const Duration highlight = Duration(seconds: 1);

  final CartLine line;
  final int number;
  final CartRowLayout layout;
  final bool selected;

  /// O'zgarsa — qator 1 s yashil (qo'shildi).
  final int? flashSeq;
  final VoidCallback onTap;
  final VoidCallback onQtyTap;
  final VoidCallback onRemove;

  @override
  State<CartLineTile> createState() => _CartLineTileState();
}

class _CartLineTileState extends State<CartLineTile> {
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
    _timer = Timer(CartLineTile.highlight, () {
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
    final layout = widget.layout;
    final unit = UnitCode.fromCode(line.unit);
    final qty = fmt.qty(line.qtyMilli, unit);
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
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(
              PosSpacing.m,
              PosSpacing.xs + 2,
              PosSpacing.xs,
              PosSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: PosRadius.controlAll,
              border: Border.all(
                color: widget.selected ? p.focus : p.border,
                width: widget.selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (layout.showNumber) ...[
                  SizedBox(
                    width: CartRowLayout.numberWidth,
                    child: Text(
                      '${widget.number}',
                      style: PosTypography.small.copyWith(
                        color: p.textMuted,
                        fontFeatures: PosTypography.tabular,
                      ),
                    ),
                  ),
                  const SizedBox(width: CartRowLayout.gap),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        line.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PosTypography.bodyStrong.copyWith(color: p.text),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: PosSpacing.s,
                        runSpacing: PosSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l10n.posUnitPriceTimes(
                              fmt.money(line.priceTiyin),
                              unit.label(l10n),
                            ),
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CartRowLayout.gap),
                _QtyButton(
                  key: ValueKey('qty-${line.id}'),
                  label: qty,
                  semanticLabel: l10n.posQtyButton(qty),
                  width: layout.qtyWidth,
                  onTap: widget.onQtyTap,
                ),
                const SizedBox(width: CartRowLayout.gap),
                SizedBox(
                  width: layout.sumWidth,
                  child: Text(
                    fmt.moneyAmount(line.totalTiyin),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: PosTypography.h3.copyWith(
                      color: p.text,
                      fontWeight: FontWeight.w700,
                      fontFeatures: PosTypography.tabular,
                    ),
                  ),
                ),
                if (layout.showRemove) ...[
                  const SizedBox(width: PosSpacing.xs),
                  PosIconButton(
                    icon: Icons.delete_outline,
                    tooltip: l10n.actionDelete,
                    onPressed: widget.onRemove,
                  ),
                ] else
                  const SizedBox(width: PosSpacing.s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miqdor: bosilsa raqamlar oynasi (kg — `0,500`). 48 dp balandlik.
class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.label,
    required this.semanticLabel,
    required this.width,
    required this.onTap,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: p.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
          side: BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: p.text.withValues(alpha: 0.04),
          child: SizedBox(
            width: width,
            height: PosSizes.touchMin,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: PosSpacing.xs),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: PosTypography.bodyStrong.copyWith(
                      color: p.text,
                      fontWeight: FontWeight.w700,
                      fontFeatures: PosTypography.tabular,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chek osti: Mijoz (F4) va Chegirma (F3), tafsilot (pozitsiyalar, oraliq
/// summa, chegirma, QQS), JAMI (eng katta matn), Naqd F9 · Karta F10 ·
/// Nasiya F11 (bir bosishda) va TO'LASH F12.
class CartSummary extends StatelessWidget {
  const CartSummary({
    required this.cart,
    required this.onDiscount,
    required this.onPay,
    required this.payEnabled,
    this.customer,
    this.onCustomer,
    this.onQuickPay,
    this.vatPayer = false,
    this.compact = false,
    super.key,
  });

  final Cart cart;
  final VoidCallback onDiscount;
  final VoidCallback onPay;
  final bool payEnabled;

  /// Chek mijozi (`null` — tanlanmagan).
  final CustomerEntry? customer;
  final VoidCallback? onCustomer;

  /// Naqd (aniq) / Karta — darhol; Nasiya — oyna.
  final ValueChanged<PayMode>? onQuickPay;

  /// Do'kon QQS to'lovchi — "QQS (12%, ichida)" qatori.
  final bool vatPayer;

  /// Telefon: yopishqoq panel — faqat JAMI va To'lash.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final p = PosPalette.of(context);
    final canPay = payEnabled && !cart.isEmpty;

    final total = Row(
      children: [
        Text(
          compact ? l10n.totalLabel : l10n.posTotalCaps,
          style: (compact ? PosTypography.bodyStrong : PosTypography.h2)
              .copyWith(
                color: p.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: PosSpacing.m),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: PosMoneyText(
              key: const ValueKey('cart-total'),
              amount: cart.totalTiyin,
              currency: fmt.currency,
              size: PosMoneySize.total,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );

    final pay = PosButton(
      key: const ValueKey('cart-pay'),
      label: compact ? l10n.actionPay : l10n.actionPayCaps,
      icon: Icons.check,
      size: compact ? PosButtonSize.m : PosButtonSize.l,
      variant: PosButtonVariant.success,
      shortcut: compact ? null : 'F12',
      expand: true,
      onPressed: canPay ? onPay : null,
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

    final discounts = cart.allDiscountsTiyin;
    final discount = cart.discount;
    final discountLabel = discount == null
        ? l10n.posDiscount
        : l10n.posDiscountActive(
            discount.isPercent
                ? fmt.percent(discount.percentBp ~/ 100)
                : fmt.money(-discount.amountTiyin),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _CustomerButton(
                customer: customer,
                onTap: onCustomer,
              ),
            ),
            const SizedBox(width: PosSpacing.s),
            Expanded(
              child: _SummaryButton(
                key: const ValueKey('cart-discount'),
                icon: Icons.percent,
                label: discountLabel,
                shortcut: 'F3',
                active: discount != null,
                onTap: cart.isEmpty ? null : onDiscount,
              ),
            ),
          ],
        ),
        const SizedBox(height: PosSpacing.s),
        _Details(
          entries: [
            (l10n.posPositions, '${cart.lines.length}', null),
            (
              l10n.posSubtotalShort,
              fmt.moneyAmount(cart.totalTiyin + discounts),
              null,
            ),
            (
              l10n.posDiscount,
              discounts > 0 ? fmt.moneyAmount(-discounts) : '0',
              discounts > 0 ? PosTone.success : null,
            ),
            if (vatPayer)
              (
                l10n.posVatIncluded,
                fmt.moneyAmount(Money.vatIncluded(cart.totalTiyin)),
                null,
              ),
          ],
        ),
        Divider(height: PosSpacing.m, color: p.border),
        total,
        const SizedBox(height: PosSpacing.s),
        Row(
          children: [
            for (final (i, (mode, label, icon, key, color)) in [
              (
                PayMode.cash,
                l10n.payCash,
                Icons.payments_outlined,
                'F9',
                p.successText,
              ),
              (
                PayMode.card,
                l10n.payCard,
                Icons.credit_card,
                'F10',
                p.primaryText,
              ),
              (
                PayMode.debt,
                l10n.payDebt,
                Icons.menu_book_outlined,
                'F11',
                p.textSecondary,
              ),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: PosSpacing.s),
              Expanded(
                child: _QuickPayButton(
                  key: ValueKey('quick-pay-${mode.name}'),
                  label: label,
                  icon: icon,
                  iconColor: color,
                  shortcut: key,
                  onTap: canPay && onQuickPay != null
                      ? () => onQuickPay!(mode)
                      : null,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: PosSpacing.s),
        pay,
      ],
    );
  }
}

/// Tafsilot: ikki ustunli ro'yxat (nom — chapda, qiymat — o'ngda).
class _Details extends StatelessWidget {
  const _Details({required this.entries});

  final List<(String, String, PosTone?)> entries;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    Widget cell((String, String, PosTone?) e) => Row(
      children: [
        Expanded(
          child: Text(
            e.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.small.copyWith(color: p.textSecondary),
          ),
        ),
        const SizedBox(width: PosSpacing.s),
        Text(
          e.$2,
          style: PosTypography.smallStrong.copyWith(
            color: e.$3 == null ? p.text : p.tone(e.$3!).text,
            fontFeatures: PosTypography.tabular,
          ),
        ),
      ],
    );
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: cell(entries[i])),
              const SizedBox(width: PosSpacing.xl),
              Expanded(
                child: i + 1 < entries.length
                    ? cell(entries[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PosSpacing.xs),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// Mijoz (F4): tanlangan bo'lsa — ism va qarzi.
class _CustomerButton extends StatelessWidget {
  const _CustomerButton({required this.customer, required this.onTap});

  final CustomerEntry? customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = context.fmt;
    final c = customer;
    if (c == null) {
      return _SummaryButton(
        key: const ValueKey('cart-customer'),
        icon: Icons.person_outline,
        label: l10n.posCustomer,
        shortcut: 'F4',
        onTap: onTap,
      );
    }
    final balance = c.balanceTiyin;
    return _SummaryButton(
      key: const ValueKey('cart-customer'),
      icon: Icons.person,
      label: c.name,
      detail: balance > 0
          ? l10n.posCustomerDebt(fmt.money(balance))
          : (balance < 0 ? l10n.posCustomerAdvance(fmt.money(-balance)) : null),
      shortcut: 'F4',
      active: true,
      onTap: onTap,
    );
  }
}

/// Chek ostidagi 56 dp tugma: ikon, yozuv (+ izoh), tezkor tugma.
class _SummaryButton extends StatelessWidget {
  const _SummaryButton({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.onTap,
    this.detail,
    this.active = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final String shortcut;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final enabled = onTap != null;
    final fg = enabled ? p.text : p.disabled;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: active ? p.primarySoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
          side: BorderSide(color: active ? p.primary : p.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: p.text.withValues(alpha: 0.04),
          child: SizedBox(
            height: PosSizes.cashierMain,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PosSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: PosSizes.iconM,
                    color: active ? p.primaryText : fg,
                  ),
                  const SizedBox(width: PosSpacing.s),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PosTypography.bodyStrong.copyWith(color: fg),
                        ),
                        if (detail != null)
                          Text(
                            detail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PosTypography.caption.copyWith(
                              color: p.textSecondary,
                              fontFeatures: PosTypography.tabular,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: PosSpacing.s),
                  PosKeycap(label: shortcut, color: p.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Naqd / Karta / Nasiya: rangli ikon, yozuv, tezkor tugma (56 dp).
class _QuickPayButton extends StatelessWidget {
  const _QuickPayButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.shortcut,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String shortcut;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
          side: BorderSide(color: p.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: p.text.withValues(alpha: 0.04),
          child: SizedBox(
            height: PosSizes.cashierMain,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PosSpacing.s),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: PosSizes.iconM,
                      color: enabled ? iconColor : p.disabled,
                    ),
                    const SizedBox(width: PosSpacing.s),
                    Text(
                      label,
                      style: PosTypography.bodyStrong.copyWith(
                        color: enabled ? p.text : p.disabled,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: PosSpacing.s),
                    PosKeycap(label: shortcut, color: p.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
