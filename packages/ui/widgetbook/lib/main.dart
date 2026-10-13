import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/catalog.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  runApp(const PosWidgetbook());
}

/// Dizayn tizimi katalogi: har komponent barcha holatlari bilan,
/// yorug'/qorong'i mavzu va 3 o'lchamda (telefon, planshet, desktop).
class PosWidgetbook extends StatelessWidget {
  const PosWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: catalog,
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: PosTheme.light()),
            WidgetbookTheme(name: 'Dark', data: PosTheme.dark()),
          ],
        ),
        ViewportAddon(const [
          ViewportData(
            name: 'Phone 390x844',
            width: 390,
            height: 844,
            pixelRatio: 3,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Tablet 1024x768',
            width: 1024,
            height: 768,
            pixelRatio: 2,
            platform: TargetPlatform.android,
          ),
          ViewportData(
            name: 'Desktop 1440x900',
            width: 1440,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.windows,
          ),
        ]),
        TextScaleAddon(divisions: 4),
      ],
    );
  }
}
