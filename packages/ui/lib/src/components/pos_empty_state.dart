import 'package:flutter/material.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_tone.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Bo'sh yoki xato holat: ikon, sarlavha, tushuntirish va amal(lar).
/// Masalan: "Tovar topilmadi. Qo'shasizmi?" + [Qo'shish].
class PosEmptyState extends StatelessWidget {
  const PosEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.secondaryAction,
    this.tone = PosTone.neutral,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Widget? secondaryAction;

  /// Xato holati uchun `danger`, ogohlantirish uchun `warning`.
  final PosTone tone;

  /// Kichik joy uchun (masalan, savat ichida).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final colors = p.tone(tone);
    final circle = compact ? 56.0 : 72.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: EdgeInsets.all(compact ? PosSpacing.l : PosSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(
                  color: tone == PosTone.neutral ? p.surfaceMuted : colors.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: compact ? PosSizes.iconL + 4 : PosSizes.iconXl + 4,
                  color: tone == PosTone.neutral
                      ? p.textSecondary
                      : colors.onSoft,
                ),
              ),
              SizedBox(height: compact ? PosSpacing.m : PosSpacing.l),
              Text(
                title,
                textAlign: TextAlign.center,
                style: (compact ? PosTypography.bodyStrong : PosTypography.h3)
                    .copyWith(color: p.text),
              ),
              if (message != null) ...[
                const SizedBox(height: PosSpacing.xs),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: (compact ? PosTypography.small : PosTypography.body)
                      .copyWith(color: p.textSecondary),
                ),
              ],
              if (action != null || secondaryAction != null) ...[
                SizedBox(height: compact ? PosSpacing.l : PosSpacing.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: PosSpacing.s,
                  runSpacing: PosSpacing.s,
                  children: [?secondaryAction, ?action],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
