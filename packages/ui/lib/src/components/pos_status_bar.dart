import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_tone.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Holat qatoridagi bitta yozuv: ikon + matn (rang yolg'iz ma'no tashimaydi).
/// Masalan: internet, printer, smena, "12 ta yozuv navbatda".
class PosStatusItem {
  const PosStatusItem({
    required this.icon,
    required this.label,
    this.tone = PosTone.neutral,
  });

  final IconData icon;
  final String label;
  final PosTone tone;
}

/// Holat qatori — doim ko'rinadi. Telefonda ekran tepasida, planshet va
/// desktopda pastda. Joy yetmasa gorizontal suriladi.
class PosStatusBar extends StatelessWidget {
  const PosStatusBar({
    required this.items,
    this.trailing,
    this.atTop = false,
    super.key,
  });

  final List<PosStatusItem> items;

  /// O'ng chetdagi qo'shimcha (masalan, kassir ismi yoki soat).
  final Widget? trailing;

  /// Tepada joylashgan (chegara pastda).
  final bool atTop;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final borderSide = BorderSide(color: p.border);

    return Container(
      height: PosSizes.statusBarHeight,
      decoration: BoxDecoration(
        color: p.surface,
        border: atTop ? Border(bottom: borderSide) : Border(top: borderSide),
      ),
      padding: const EdgeInsets.symmetric(horizontal: PosSpacing.l),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0) const SizedBox(width: PosSpacing.xl),
                    _StatusItem(item: item),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: PosSpacing.l),
            DefaultTextStyle.merge(
              style: PosTypography.small.copyWith(color: p.textSecondary),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.item});

  final PosStatusItem item;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final color = item.tone == PosTone.neutral
        ? p.textSecondary
        : p.tone(item.tone).text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: PosSizes.iconS, color: color),
        const SizedBox(width: PosSpacing.xs + 2),
        Text(
          item.label,
          style: PosTypography.small.copyWith(
            color: color,
            fontWeight: item.tone == PosTone.neutral
                ? FontWeight.w400
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
