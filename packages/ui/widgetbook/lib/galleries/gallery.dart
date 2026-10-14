import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';

/// Galereya sahifasi: bo'limlar ketma-ket, telefonda ham sig'adigan Wrap.
/// Widgetbook "All states" va golden testlar aynan shu sahifalarni ko'rsatadi.
class GalleryPage extends StatelessWidget {
  const GalleryPage({required this.sections, super.key});

  final List<GallerySection> sections;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    return ColoredBox(
      color: p.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? PosSpacing.l : PosSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, section) in sections.indexed) ...[
              if (i > 0)
                SizedBox(height: compact ? PosSpacing.l : PosSpacing.xl),
              section,
            ],
          ],
        ),
      ),
    );
  }
}

class GallerySection extends StatelessWidget {
  const GallerySection({
    required this.title,
    required this.children,
    this.spacing = PosSpacing.m,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: PosTypography.caption.copyWith(
            color: p.textSecondary,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PosSpacing.s),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ],
    );
  }
}

void noop() {}
void noopValue<T>(T _) {}
