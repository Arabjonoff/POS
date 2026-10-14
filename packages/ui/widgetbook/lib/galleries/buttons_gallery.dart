import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

/// Button va IconButton: variantlar, o'lchamlar, holatlar.
class ButtonsGallery extends StatelessWidget {
  const ButtonsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return const GalleryPage(
      sections: [
        GallerySection(
          title: 'Variantlar',
          children: [
            PosButton(label: "To'lash", onPressed: noop),
            PosButton(
              label: 'Bekor',
              variant: PosButtonVariant.secondary,
              onPressed: noop,
            ),
            PosButton(
              label: "O'chirish",
              variant: PosButtonVariant.danger,
              onPressed: noop,
            ),
            PosButton(
              label: 'Batafsil',
              variant: PosButtonVariant.ghost,
              onPressed: noop,
            ),
          ],
        ),
        GallerySection(
          title: "O'lchamlar: s 48 · m 56 · l 64 · xl 80",
          children: [
            PosButton(label: 's', size: PosButtonSize.s, onPressed: noop),
            PosButton(label: 'm', onPressed: noop),
            PosButton(label: 'l', size: PosButtonSize.l, onPressed: noop),
            PosButton(
              label: "To'lash",
              size: PosButtonSize.xl,
              shortcut: 'F12',
              icon: Icons.payments_outlined,
              onPressed: noop,
            ),
          ],
        ),
        GallerySection(
          title: 'Holatlar',
          children: [
            PosButton(label: 'Ikon', icon: Icons.add, onPressed: noop),
            PosButton(label: 'Yuklanmoqda', loading: true, onPressed: noop),
            PosButton(label: "O'chiq", onPressed: null),
            PosButton(
              label: "O'chiq",
              variant: PosButtonVariant.secondary,
              onPressed: null,
            ),
            PosButton(
              label: 'Qidiruv',
              variant: PosButtonVariant.secondary,
              icon: Icons.search,
              shortcut: 'F1',
              onPressed: noop,
            ),
          ],
        ),
        GallerySection(
          title: 'IconButton',
          spacing: PosSpacing.s,
          children: [
            PosIconButton(
              icon: Icons.more_vert,
              tooltip: 'standard',
              onPressed: noop,
            ),
            PosIconButton(
              icon: Icons.add,
              tooltip: 'filled',
              variant: PosIconButtonVariant.filled,
              onPressed: noop,
            ),
            PosIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'tonal',
              variant: PosIconButtonVariant.tonal,
              onPressed: noop,
            ),
            PosIconButton(
              icon: Icons.print_outlined,
              tooltip: 'outlined',
              variant: PosIconButtonVariant.outlined,
              onPressed: noop,
            ),
            PosIconButton(
              icon: Icons.delete_outline,
              tooltip: 'danger',
              variant: PosIconButtonVariant.danger,
              onPressed: noop,
            ),
            PosIconButton(
              icon: Icons.add,
              tooltip: 'disabled',
              variant: PosIconButtonVariant.filled,
              onPressed: null,
            ),
            PosIconButton(
              icon: Icons.qr_code_scanner,
              tooltip: '56',
              variant: PosIconButtonVariant.outlined,
              size: PosSizes.cashierMain,
              onPressed: noop,
            ),
          ],
        ),
      ],
    );
  }
}
