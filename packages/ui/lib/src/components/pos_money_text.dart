import 'package:flutter/material.dart';
import 'package:pos_ui/src/format/pos_format.dart';
import 'package:pos_ui/src/tokens/pos_breakpoints.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_tone.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Summa o'lchami. [total] — jami summa, ekrandagi eng katta matn:
/// telefonda 32, kichik planshetda 40, planshet/desktopda 48.
enum PosMoneySize { total, large, medium, body, small }

/// Summa: `125 000 so'm`. Ichkarida tiyin (`int`), raqamlar bir xil kenglikda.
class PosMoneyText extends StatelessWidget {
  const PosMoneyText({
    required this.amount,
    required this.currency,
    this.size = PosMoneySize.body,
    this.tone,
    this.textAlign,
    super.key,
  });

  /// Summa tiyinda.
  final int amount;

  /// Valyuta nomi tarjimadan: "so'm", "сўм", "сум".
  final String currency;
  final PosMoneySize size;

  /// `null` — oddiy matn rangi; `success` — qaytim, `danger` — qarz.
  final PosTone? tone;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final base = switch (size) {
      PosMoneySize.total => switch (PosWindowSize.of(context)) {
        PosWindowSize.compact => PosTypography.displaySmall,
        PosWindowSize.medium => PosTypography.displayMedium,
        _ => PosTypography.displayLarge,
      },
      PosMoneySize.large => PosTypography.h1,
      PosMoneySize.medium => PosTypography.h3,
      PosMoneySize.body => PosTypography.bodyStrong,
      PosMoneySize.small => PosTypography.small,
    };
    final color = tone == null || tone == PosTone.neutral
        ? p.text
        : p.tone(tone!).text;
    final text = PosFormat.money(amount, currency: currency);

    final widget = Text(
      text,
      maxLines: 1,
      softWrap: false,
      textAlign: textAlign,
      style: base.copyWith(
        color: color,
        fontFeatures: PosTypography.tabular,
      ),
    );
    if (size != PosMoneySize.total) return widget;
    // Juda katta summa ham bir qatorda sig'adi.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: switch (textAlign) {
        TextAlign.right || TextAlign.end => Alignment.centerRight,
        TextAlign.center => Alignment.center,
        _ => Alignment.centerLeft,
      },
      child: widget,
    );
  }
}
