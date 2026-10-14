import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

/// NumericKeypad (summa kiritish uchun `00`, vazn uchun `,`).
class KeypadGallery extends StatelessWidget {
  const KeypadGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return GalleryPage(
      sections: [
        GallerySection(
          title: 'Summa kiritish (00)',
          children: [
            SizedBox(
              width: 340,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const PosMoneyText(
                    amount: 15000000,
                    currency: "so'm",
                    size: PosMoneySize.large,
                  ),
                  Text(
                    'Qaytim',
                    style: PosTypography.small.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const PosMoneyText(
                    amount: 2500000,
                    currency: "so'm",
                    size: PosMoneySize.large,
                    tone: PosTone.success,
                  ),
                  const SizedBox(height: PosSpacing.m),
                  const PosNumericKeypad(
                    onKey: noopValue,
                    onBackspace: noop,
                    backspaceTooltip: "O'chirish",
                    extraKey: '00',
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 340,
              child: PosNumericKeypad(
                onKey: noopValue,
                onBackspace: noop,
                backspaceTooltip: "O'chirish",
                extraKey: ',',
                enabled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// PinPad: oddiy va xato holati.
class PinPadGallery extends StatelessWidget {
  const PinPadGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return const GalleryPage(
      sections: [
        GallerySection(
          title: 'PinPad',
          spacing: PosSpacing.xxl,
          children: [
            SizedBox(
              width: 340,
              child: PosPinPad(
                filled: 2,
                onDigit: noopValue,
                onBackspace: noop,
                backspaceTooltip: "O'chirish",
                autofocus: false,
              ),
            ),
            SizedBox(
              width: 340,
              child: PosPinPad(
                filled: 4,
                onDigit: noopValue,
                onBackspace: noop,
                backspaceTooltip: "O'chirish",
                errorText: "PIN noto'g'ri. 1 daqiqadan keyin urinib ko'ring",
                enabled: false,
                autofocus: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
