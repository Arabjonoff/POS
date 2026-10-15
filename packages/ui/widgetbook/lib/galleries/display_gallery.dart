import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

/// MoneyText, Badge, StatusDot, ProductTile, Card, ListTile.
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
          title: 'ProductTile',
          children: [
            for (final (i, name, price, unit, stock, low, out, selected) in [
              (
                0,
                'Non issiq',
                '4 000',
                "so'm/dona",
                '24 dona',
                false,
                false,
                false,
              ),
              (
                1,
                'Sut 1 L',
                '9 500',
                "so'm/dona",
                '3 dona',
                true,
                false,
                false,
              ),
              (
                3,
                'Kartoshka',
                '6 500',
                "so'm/kg",
                '52,500 kg',
                false,
                false,
                true,
              ),
              (
                4,
                'Guruch lazer',
                '18 000',
                "so'm/kg",
                "Qoldiq yo'q",
                false,
                true,
                false,
              ),
              (
                2,
                'Shokolad Alpen Gold 90 g',
                '12 000',
                "so'm/dona",
                null,
                false,
                false,
                false,
              ),
            ])
              SizedBox(
                width: 180,
                height: PosProductTile.height,
                child: PosProductTile(
                  name: name,
                  price: price,
                  unit: unit,
                  accent: p.categoryAccent(i),
                  stock: stock,
                  lowLabel: low ? 'Kam' : null,
                  out: out,
                  selected: selected,
                  onTap: noop,
                ),
              ),
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
