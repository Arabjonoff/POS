import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

/// MoneyText, Badge, StatusDot, Card, ListTile.
class DisplayGallery extends StatelessWidget {
  const DisplayGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return GalleryPage(
      sections: [
        const GallerySection(
          title: 'MoneyText',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PosMoneyText(
                  amount: 12500000,
                  currency: "so'm",
                  size: PosMoneySize.total,
                ),
                Wrap(
                  spacing: PosSpacing.l,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    PosMoneyText(
                      amount: 2500000,
                      currency: "so'm",
                      size: PosMoneySize.large,
                      tone: PosTone.success,
                    ),
                    PosMoneyText(
                      amount: -4500050,
                      currency: "so'm",
                      size: PosMoneySize.medium,
                      tone: PosTone.danger,
                    ),
                    PosMoneyText(amount: 990000, currency: "so'm"),
                    PosMoneyText(
                      amount: 15000,
                      currency: "so'm",
                      size: PosMoneySize.small,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GallerySection(
          title: 'Badge',
          spacing: PosSpacing.s,
          children: [
            for (final tone in PosTone.values)
              PosBadge(label: _toneLabel(tone), tone: tone),
            const PosBadge(
              label: "To'langan",
              tone: PosTone.success,
              icon: Icons.check,
              large: true,
            ),
            const PosBadge(label: '12', tone: PosTone.danger, solid: true),
          ],
        ),
        GallerySection(
          title: 'StatusDot',
          spacing: PosSpacing.l,
          children: [
            for (final tone in PosTone.values)
              PosStatusDot(label: _toneLabel(tone), tone: tone),
          ],
        ),
        GallerySection(
          title: 'Card',
          children: [
            for (final (title, selected, muted) in [
              ('Oddiy', false, false),
              ('Tanlangan', true, false),
              ('Kulrang', false, true),
            ])
              SizedBox(
                width: 160,
                child: PosCard(
                  selected: selected,
                  muted: muted,
                  onTap: noop,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PosTypography.bodyStrong.copyWith(
                          color: p.text,
                        ),
                      ),
                      const PosMoneyText(
                        amount: 1250000,
                        currency: "so'm",
                        size: PosMoneySize.small,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const GallerySection(
          title: 'ListTile',
          children: [
            SizedBox(
              width: 360,
              child: PosCard(
                padding: EdgeInsets.all(PosSpacing.xs),
                child: Column(
                  children: [
                    PosListTile(
                      leading: Icon(Icons.bakery_dining_outlined),
                      title: 'Non "Buxoro"',
                      subtitle: '2 dona × 5 000',
                      trailing: PosMoneyText(
                        amount: 1000000,
                        currency: "so'm",
                      ),
                      onTap: noop,
                    ),
                    PosListTile(
                      leading: Icon(Icons.water_drop_outlined),
                      title: 'Sut 1 l',
                      subtitle: '1 dona × 12 000',
                      trailing: PosMoneyText(
                        amount: 1200000,
                        currency: "so'm",
                      ),
                      selected: true,
                      onTap: noop,
                    ),
                    PosListTile(
                      leading: Icon(Icons.block),
                      title: 'Sotuvda yo‘q',
                      subtitle: 'Qoldiq 0',
                      enabled: false,
                      onTap: noop,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _toneLabel(PosTone tone) => switch (tone) {
    PosTone.neutral => 'Qoralama',
    PosTone.primary => 'Yangi',
    PosTone.success => 'Internet bor',
    PosTone.warning => 'Kam qoldi',
    PosTone.danger => 'Qarz',
  };
}
