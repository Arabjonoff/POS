import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_tone.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Kichik yorliq (holat, son). Yumshoq fon + to'q matn; ixtiyoriy ikon.
class PosBadge extends StatelessWidget {
  const PosBadge({
    required this.label,
    this.tone = PosTone.neutral,
    this.icon,
    this.large = false,
    this.solid = false,
    super.key,
  });

  final String label;
  final PosTone tone;
  final IconData? icon;

  /// 28 dp (oddiy 24 dp).
  final bool large;

  /// To'liq bo'yalgan (masalan, navigatsiyadagi son).
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final c = PosPalette.of(context).tone(tone);
    final bg = solid ? c.fill : c.soft;
    final fg = solid ? c.onFill : c.onSoft;
    final style = (large ? PosTypography.smallStrong : PosTypography.caption)
        .copyWith(color: fg, fontWeight: FontWeight.w600, height: 1.2);

    return Container(
      constraints: BoxConstraints(minHeight: large ? 28 : 24, minWidth: 24),
      padding: EdgeInsets.symmetric(
        horizontal: large ? PosSpacing.m - 2 : PosSpacing.s,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: PosRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: large ? PosSizes.iconS : 14, color: fg),
            const SizedBox(width: PosSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
