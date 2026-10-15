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
    this.short,
  });

  final IconData icon;
  final String label;

  /// Neytral — hammasi joyida (rangsiz). Rang faqat muammoda.
  final PosTone tone;

  /// Tor ekranda neytral yozuv o'rniga (masalan, navbat soni `12`);
  /// `null` — faqat ikon (to'liq matn — tooltip va ekran o'quvchida).
  final String? short;
}

/// Holat qatori — doim ko'rinadi. Telefonda ekran tepasida, planshet va
/// desktopda pastda. Joy yetmasa gorizontal suriladi.
class PosStatusBar extends StatelessWidget {
  const PosStatusBar({
    required this.items,
    this.trailing,
    this.atTop = false,
    this.compact = false,
    super.key,
  });

  final List<PosStatusItem> items;

  /// O'ng chetdagi qo'shimcha (masalan, kassir ismi yoki soat).
  final Widget? trailing;

  /// Tepada joylashgan (chegara pastda).
  final bool atTop;

  /// Telefon: neytral yozuvlar ikon (+ qisqa matn), muammolar — to'liq va
  /// birinchi; hammasi bir qatorga sig'adi.
  final bool compact;

  /// Telefonda muammolar birinchi (ko'rinmay qolmasin).
  List<PosStatusItem> get _ordered => compact
      ? [
          ...items.where((i) => i.tone != PosTone.neutral),
          ...items.where((i) => i.tone == PosTone.neutral),
        ]
      : items;

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
                  for (final (i, item) in _ordered.indexed) ...[
                    if (i > 0)
                      SizedBox(
                        width: compact ? PosSpacing.m : PosSpacing.xl,
                      ),
                    _StatusItem(item: item, compact: compact),
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
  const _StatusItem({required this.item, required this.compact});

  final PosStatusItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final neutral = item.tone == PosTone.neutral;
    final color = neutral ? p.textSecondary : p.tone(item.tone).text;
    final text = compact && neutral ? item.short : item.label;
    return Tooltip(
      message: item.label,
      child: Semantics(
        label: item.label,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: PosSizes.iconS, color: color),
            if (text != null) ...[
              const SizedBox(width: PosSpacing.xs + 2),
              Text(
                text,
                style: PosTypography.small.copyWith(
                  color: color,
                  fontWeight: neutral ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
