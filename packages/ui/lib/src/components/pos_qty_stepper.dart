import 'package:flutter/material.dart';
import 'package:pos_ui/src/format/pos_format.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Miqdorni − / + bilan o'zgartirish. Qiymat `qty_milli` (1 dona = 1000).
/// O'rtadagi qiymatni bosish ([onValueTap]) — raqamli klaviaturani ochish uchun.
class PosQtyStepper extends StatelessWidget {
  const PosQtyStepper({
    required this.valueMilli,
    required this.onChanged,
    required this.decrementTooltip,
    required this.incrementTooltip,
    this.stepMilli = 1000,
    this.minMilli = 0,
    this.maxMilli,
    this.weighted = false,
    this.unit,
    this.onValueTap,
    this.large = false,
    super.key,
  }) : assert(stepMilli > 0, 'Qadam musbat bo‘lishi kerak');

  final int valueMilli;
  final ValueChanged<int>? onChanged;
  final String decrementTooltip;
  final String incrementTooltip;
  final int stepMilli;
  final int minMilli;
  final int? maxMilli;

  /// Vaznli tovar — qiymat 3 kasr xonasi bilan.
  final bool weighted;

  /// Birlik nomi tarjimadan (`kg`, `dona`).
  final String? unit;
  final VoidCallback? onValueTap;

  /// 56 dp (kassa savati), oddiy — 48 dp.
  final bool large;

  bool get _canDecrement =>
      onChanged != null && valueMilli - stepMilli >= minMilli;

  bool get _canIncrement =>
      onChanged != null &&
      (maxMilli == null || valueMilli + stepMilli <= maxMilli!);

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final side = large ? PosSizes.cashierMain : PosSizes.touchMin;
    final text = unit == null
        ? PosFormat.qty(valueMilli, weighted: weighted)
        : PosFormat.qtyWithUnit(valueMilli, unit: unit!, weighted: weighted);

    Widget stepButton(IconData icon, String tooltip, VoidCallback? onTap) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          icon: Icon(icon),
          iconSize: PosSizes.iconL,
          style: IconButton.styleFrom(
            fixedSize: Size.square(side),
            minimumSize: Size.square(side),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: p.text,
            disabledForegroundColor: p.disabled,
            shape: const RoundedRectangleBorder(
              borderRadius: PosRadius.controlAll,
            ),
          ),
        );

    final value = ConstrainedBox(
      constraints: BoxConstraints(minWidth: large ? 72 : 56, minHeight: side),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PosSpacing.s),
          child: Text(
            text,
            maxLines: 1,
            style: (large ? PosTypography.h3 : PosTypography.bodyStrong)
                .copyWith(color: p.text, fontFeatures: PosTypography.tabular),
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: PosRadius.controlAll,
        border: Border.all(color: p.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          stepButton(
            Icons.remove,
            decrementTooltip,
            _canDecrement ? () => onChanged!(valueMilli - stepMilli) : null,
          ),
          if (onValueTap == null)
            value
          else
            InkWell(
              onTap: onValueTap,
              borderRadius: PosRadius.inputAll,
              child: value,
            ),
          stepButton(
            Icons.add,
            incrementTooltip,
            _canIncrement ? () => onChanged!(valueMilli + stepMilli) : null,
          ),
        ],
      ),
    );
  }
}
