import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

/// Xavfli amalni tasdiqlash oynasi (namuna).
Future<void> openSampleDialog(BuildContext context) => showPosDialog<void>(
  context: context,
  builder: (context) => PosDialog(
    icon: Icons.delete_outline,
    iconTone: PosTone.danger,
    title: 'Chekni bekor qilasizmi?',
    message: 'Savatdagi 3 ta tovar o‘chiriladi. Buni qaytarib bo‘lmaydi.',
    actions: [
      PosButton(
        label: 'Yo‘q',
        variant: PosButtonVariant.secondary,
        shortcut: 'Esc',
        onPressed: () => Navigator.of(context).pop(),
      ),
      PosButton(
        label: 'Ha, bekor qilish',
        variant: PosButtonVariant.danger,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  ),
);

/// Oyna: tugmani bosing — telefonda pastdan panel, kattaroq ekranda dialog.
class DialogGallery extends StatelessWidget {
  const DialogGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GalleryPage(
        sections: [
          GallerySection(
            title: 'Dialog / BottomSheet',
            children: [
              Builder(
                builder: (context) => PosButton(
                  label: 'Oynani ochish',
                  variant: PosButtonVariant.secondary,
                  onPressed: () => openSampleDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
