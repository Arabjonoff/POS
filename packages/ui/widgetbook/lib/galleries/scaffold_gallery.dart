import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/gallery.dart';

const List<PosDestination> sampleDestinations = [
  PosDestination(
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
    label: 'Kassa',
    shortcut: 'F3',
  ),
  PosDestination(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'Tovarlar',
    badgeCount: 4,
  ),
  PosDestination(
    icon: Icons.move_to_inbox_outlined,
    selectedIcon: Icons.move_to_inbox,
    label: 'Kirim',
  ),
  PosDestination(
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    label: 'Nasiya',
  ),
  PosDestination(
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    label: 'Hisobotlar',
  ),
  PosDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Sozlamalar',
  ),
];

/// ResponsiveScaffold + StatusBar: telefon, planshet, desktop.
class ScaffoldGallery extends StatefulWidget {
  const ScaffoldGallery({super.key});

  @override
  State<ScaffoldGallery> createState() => _ScaffoldGalleryState();
}

class _ScaffoldGalleryState extends State<ScaffoldGallery> {
  int _selected = 0;
  bool _navExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    return PosResponsiveScaffold(
      destinations: sampleDestinations,
      selectedIndex: _selected,
      onDestinationSelected: (i) => setState(() => _selected = i),
      navExpanded: _navExpanded,
      onNavExpandedChanged: (v) => setState(() => _navExpanded = v),
      expandNavTooltip: 'Menyuni ochish · Ctrl+B',
      collapseNavTooltip: 'Menyuni yig‘ish · Ctrl+B',
      railFooter: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 18, child: Text('A')),
          SizedBox(height: PosSpacing.xs),
          PosIconButton(
            icon: Icons.lock_outline,
            tooltip: 'Qulflash',
            onPressed: noop,
          ),
        ],
      ),
      header: Row(
        children: [
          Icon(Icons.storefront, color: p.primaryText),
          const SizedBox(width: PosSpacing.s),
          Expanded(
            child: Text(
              'Baraka do‘koni',
              overflow: TextOverflow.ellipsis,
              style: PosTypography.h3.copyWith(color: p.text),
            ),
          ),
        ],
      ),
      footer: const PosListTile(
        leading: CircleAvatar(radius: 16, child: Text('A')),
        title: 'Aziza',
        subtitle: 'Kassir',
        padding: EdgeInsets.symmetric(horizontal: PosSpacing.s),
      ),
      statusBar: PosStatusBar(
        atTop: compact,
        compact: compact,
        items: const [
          PosStatusItem(
            icon: Icons.wifi_off,
            label: 'Internet yo‘q — oflayn rejimda ishlayapti',
            tone: PosTone.danger,
            onTap: noop,
          ),
          PosStatusItem(
            icon: Icons.sync,
            label: '12 ta yozuv navbatda',
            tone: PosTone.warning,
            onTap: noop,
          ),
          PosStatusItem(
            icon: Icons.print_outlined,
            label: 'Printer sozlanmagan',
            tone: PosTone.warning,
            onTap: noop,
          ),
          PosStatusItem(
            icon: Icons.work_history_outlined,
            label: 'Smena ochiq · 08:02 dan',
            onTap: noop,
          ),
        ],
        trailing: compact ? null : const Text('Aziza · Kassir   14:05'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(PosSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PosSearchField(
              hint: 'Shtrix-kod yoki nom',
              clearTooltip: 'Tozalash',
              shortcut: 'F1',
              large: true,
            ),
            const SizedBox(height: PosSpacing.l),
            const Expanded(
              child: PosCard(
                child: PosEmptyState(
                  icon: Icons.qr_code_scanner,
                  title: 'Savat bo‘sh',
                  message: 'Tovarni skanerlang yoki nomini yozing',
                  action: PosButton(
                    label: 'Tovar tanlash',
                    variant: PosButtonVariant.secondary,
                    icon: Icons.grid_view,
                    onPressed: noop,
                  ),
                ),
              ),
            ),
            const SizedBox(height: PosSpacing.l),
            Row(
              children: [
                const Expanded(
                  child: PosMoneyText(
                    amount: 0,
                    currency: "so'm",
                    size: PosMoneySize.total,
                  ),
                ),
                const SizedBox(width: PosSpacing.l),
                PosButton(
                  label: "To'lash",
                  size: PosButtonSize.xl,
                  shortcut: compact ? null : 'F12',
                  onPressed: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
