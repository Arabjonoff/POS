import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Katalog tarkibi. Har yangi komponent shu yerga use-case sifatida qo'shiladi (T-030).
final List<WidgetbookNode> catalog = [
  WidgetbookFolder(
    name: 'Tokens',
    children: [
      WidgetbookComponent(
        name: 'Colors',
        useCases: [
          WidgetbookUseCase(
            name: 'Color scheme',
            builder: (context) => const _ColorSchemePreview(),
          ),
        ],
      ),
    ],
  ),
];

class _ColorSchemePreview extends StatelessWidget {
  const _ColorSchemePreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final swatches = <String, Color>{
      'primary': scheme.primary,
      'error': scheme.error,
      'surface': scheme.surface,
      'onSurface': scheme.onSurface,
      'onSurfaceVariant': scheme.onSurfaceVariant,
      'outline': scheme.outline,
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final entry in swatches.entries)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 64,
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outline),
                  ),
                ),
                const SizedBox(height: 4),
                Text(entry.key),
              ],
            ),
        ],
      ),
    );
  }
}
