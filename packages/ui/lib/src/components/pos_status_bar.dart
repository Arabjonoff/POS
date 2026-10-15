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
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Neytral — hammasi joyida (rangsiz). Rang faqat muammoda.
  final PosTone tone;

  /// Tor ekranda neytral yozuv o'rniga (masalan, navbat soni `12`);
  /// `null` — faqat ikon (to'liq matn — tooltip va ekran o'quvchida).
  final String? short;

  /// Bosilsa (masalan, tegishli sozlamaga o'tish). Planshet/desktopda
  /// yozuv 48 dp balandlikdagi tugma bo'ladi.
  final VoidCallback? onTap;
}

/// Holat qatori — doim ko'rinadi. Telefonda ekran tepasida (40 dp), planshet
/// va desktopda pastda (48 dp, muammoli yozuv yumshoq fonda). Joy yetmasa
/// gorizontal suriladi.
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
      // Katta panelda: 48 dp yozuvlar + 1 dp chegara.
      height: compact
          ? PosSizes.statusBarHeight
          : PosSizes.statusBarHeightLarge + 1,
      decoration: BoxDecoration(
        color: p.surface,
        border: atTop ? Border(bottom: borderSide) : Border(top: borderSide),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? PosSpacing.l : PosSpacing.s,
      ),
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
                        width: compact ? PosSpacing.m : PosSpacing.xs,
                      ),
                    _StatusItem(item: item, compact: compact),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: compact ? PosSpacing.l : PosSpacing.m),
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
    final tone = p.tone(item.tone);
    // Katta panelda muammo yumshoq fonda — matn rangi fon ustida AA.
    final soft = !compact && !neutral;
    final color = neutral
        ? p.textSecondary
        : (soft ? tone.onSoft : tone.text);
    final text = compact && neutral ? item.short : item.label;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          item.icon,
          size: compact ? PosSizes.iconS : PosSizes.iconM,
          color: color,
        ),
        if (text != null) ...[
          SizedBox(width: compact ? PosSpacing.xs + 2 : PosSpacing.s),
          Text(
            text,
            style: (compact ? PosTypography.small : PosTypography.body)
                .copyWith(
                  color: color,
                  fontWeight: neutral ? FontWeight.w400 : FontWeight.w600,
                ),
          ),
        ],
      ],
    );
    if (compact) {
      return Tooltip(
        message: item.label,
        child: Semantics(
          label: item.label,
          excludeSemantics: true,
          child: content,
        ),
      );
    }
    final box = Container(
      height: PosSizes.touchMin,
      padding: const EdgeInsets.symmetric(horizontal: PosSpacing.m),
      alignment: Alignment.center,
      child: content,
    );
    return Semantics(
      label: item.label,
      button: item.onTap != null,
      excludeSemantics: true,
      child: Material(
        color: soft ? tone.soft : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(PosRadius.input)),
        clipBehavior: Clip.antiAlias,
        child: item.onTap == null
            ? box
            : InkWell(
                onTap: item.onTap,
                hoverColor: p.text.withValues(alpha: 0.04),
                focusColor: p.primary.withValues(alpha: 0.12),
                child: box,
              ),
      ),
    );
  }
}
