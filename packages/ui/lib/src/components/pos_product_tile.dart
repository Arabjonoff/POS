import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Kassa tovar kartasi (panjarada, ≥ 160 × 112 dp): chapda kategoriya rangi
/// chizig'i, rasm yoki bosh harf, nom (2 qator), narx (qalin) va birlik,
/// qoldiq. Kam qolgan — sariq belgi; qoldiq yo'q — kulrang karta (bosish
/// mumkin, ekran ogohlantiradi).
class PosProductTile extends StatelessWidget {
  const PosProductTile({
    required this.name,
    required this.price,
    required this.unit,
    required this.onTap,
    this.accent,
    this.image,
    this.stock,
    this.lowLabel,
    this.out = false,
    this.selected = false,
    this.semanticLabel,
    super.key,
  });

  /// Panjara katagi: eng kichik kenglik va balandlik.
  static const double minWidth = 160;
  static const double height = 112;

  final String name;

  /// Valyutasiz summa (`4 000`), qalin raqamlar.
  final String price;

  /// Narx yonidagi kichik matn: `so'm/dona`.
  final String unit;
  final VoidCallback onTap;

  /// Kategoriya rangi; `null` — chegara rangi.
  final Color? accent;

  /// Kichik rasm (36 × 36); `null` — bosh harf.
  final Widget? image;

  /// Qoldiq matni (`24 dona`); `null` — ko'rsatilmaydi.
  final String? stock;

  /// Berilsa — kam qolgan (sariq belgi, masalan `Kam`).
  final String? lowLabel;

  /// Qoldiq yo'q: kulrang.
  final bool out;

  /// Klaviatura bilan tanlangan (↑/↓): ko'k chegara.
  final bool selected;
  final String? semanticLabel;

  static const double _avatar = 36;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final stripe = out ? p.borderStrong : (accent ?? p.borderStrong);
    final fg = out ? p.textSecondary : p.text;
    final dark = p.brightness == Brightness.dark;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();

    final avatar = SizedBox.square(
      dimension: _avatar,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(PosRadius.input)),
        child:
            image ??
            ColoredBox(
              color: out
                  ? p.border
                  : stripe.withValues(alpha: dark ? 0.2 : 0.1),
              child: Center(
                child: Text(
                  initial,
                  style: PosTypography.bodyStrong.copyWith(
                    color: out ? p.textSecondary : stripe,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: out ? p.surfaceMuted : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: PosRadius.controlAll,
          side: selected
              ? BorderSide(color: p.focus, width: 2)
              : BorderSide(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: p.text.withValues(alpha: 0.04),
          focusColor: p.primary.withValues(alpha: 0.12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: stripe),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PosSpacing.s + 2,
                    PosSpacing.s + 2,
                    PosSpacing.m,
                    PosSpacing.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatar,
                          const SizedBox(width: PosSpacing.s + 2),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: PosTypography.smallStrong.copyWith(
                                color: fg,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PosTypography.h3.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w700,
                                fontFeatures: PosTypography.tabular,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: PosSpacing.xs + 2),
                          Text(
                            unit,
                            maxLines: 1,
                            style: PosTypography.caption.copyWith(
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (stock != null || lowLabel != null)
                        Row(
                          children: [
                            if (lowLabel != null) ...[
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: p.warningSoft,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(4),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: PosSpacing.xs + 2,
                                    vertical: 1,
                                  ),
                                  child: Text(
                                    lowLabel!,
                                    style: PosTypography.caption.copyWith(
                                      color: p.onWarningSoft,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: PosSpacing.xs + 2),
                            ],
                            if (stock != null)
                              Flexible(
                                child: Text(
                                  stock!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PosTypography.caption.copyWith(
                                    color: out ? p.textSecondary : p.textMuted,
                                    fontFeatures: PosTypography.tabular,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
