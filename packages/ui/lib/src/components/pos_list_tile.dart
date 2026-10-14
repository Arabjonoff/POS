import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Ro'yxat qatori: kamida 56 dp, chap ikon/avatar, sarlavha, izoh, o'ng qism.
class PosListTile extends StatelessWidget {
  const PosListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PosSpacing.l,
      vertical: PosSpacing.s,
    ),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final titleColor = !enabled
        ? p.disabled
        : (selected ? p.onPrimarySoft : p.text);
    final subtitleColor = !enabled
        ? p.disabled
        : (selected ? p.onPrimarySoft : p.textSecondary);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: PosSizes.cashierMain),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(
                  color: selected ? p.onPrimarySoft : p.textSecondary,
                ),
                child: leading!,
              ),
              const SizedBox(width: PosSpacing.m),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PosTypography.body.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PosTypography.small.copyWith(color: subtitleColor),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: PosSpacing.m),
              DefaultTextStyle.merge(
                style: PosTypography.body.copyWith(color: titleColor),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );

    return Material(
      color: selected ? p.primarySoft : Colors.transparent,
      borderRadius: PosRadius.controlAll,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? row
          : InkWell(
              onTap: enabled ? onTap : null,
              hoverColor: p.text.withValues(alpha: 0.04),
              focusColor: p.primary.withValues(alpha: 0.10),
              child: row,
            ),
    );
  }
}
