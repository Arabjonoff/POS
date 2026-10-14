import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

/// Toast, EmptyState, Skeleton, ScanFeedback.
class FeedbackGallery extends StatelessWidget {
  const FeedbackGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    const width = 360.0;
    return GalleryPage(
      sections: [
        const GallerySection(
          title: 'Toast',
          spacing: PosSpacing.s,
          children: [
            SizedBox(
              width: width,
              child: PosToast(
                message: 'Qator o‘chirildi',
                actionLabel: 'Bekor qilish',
                onAction: noop,
              ),
            ),
            SizedBox(
              width: width,
              child: PosToast(
                message: 'Savdo saqlandi',
                tone: PosTone.success,
              ),
            ),
            SizedBox(
              width: width,
              child: PosToast(
                message: 'Internet yo‘q — savdolar saqlanyapti (12)',
                tone: PosTone.warning,
              ),
            ),
            SizedBox(
              width: width,
              child: PosToast(
                message: 'Printer topilmadi',
                tone: PosTone.danger,
              ),
            ),
          ],
        ),
        const GallerySection(
          title: 'EmptyState',
          children: [
            SizedBox(
              width: width,
              child: PosCard(
                child: PosEmptyState(
                  icon: Icons.search_off,
                  title: 'Tovar topilmadi',
                  message: "“sut 2” bo'yicha hech narsa yo'q. Qo'shasizmi?",
                  compact: true,
                  action: PosButton(
                    label: "Qo'shish",
                    size: PosButtonSize.s,
                    icon: Icons.add,
                    onPressed: noop,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: PosCard(
                child: PosEmptyState(
                  icon: Icons.cloud_off,
                  title: 'Maʼlumot yuklanmadi',
                  message: 'Internet qaytganda yana urinib ko‘ramiz',
                  tone: PosTone.danger,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
        const GallerySection(
          title: 'Skeleton',
          children: [
            SizedBox(
              width: width,
              child: PosCard(
                padding: EdgeInsets.symmetric(vertical: PosSpacing.xs),
                child: Column(
                  children: [
                    PosSkeletonListTile(),
                    PosSkeletonListTile(),
                    PosSkeletonListTile(showLeading: false),
                  ],
                ),
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'ScanFeedback',
          children: [
            for (final (result, label) in [
              (PosScanResult.success, 'Qo‘shildi'),
              (PosScanResult.warning, 'Topilmadi'),
              (PosScanResult.error, 'Xato'),
            ])
              SizedBox(
                width: 112,
                height: 64,
                child: Stack(
                  children: [
                    PosCard(
                      child: Center(
                        child: Text(
                          label,
                          style: PosTypography.small.copyWith(color: p.text),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: PosScanFeedbackOverlay(result: result),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
