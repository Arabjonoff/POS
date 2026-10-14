import 'package:flutter/material.dart';
import 'package:pos_ui/src/components/pos_button.dart';
import 'package:pos_ui/src/tokens/pos_breakpoints.dart';
import 'package:pos_ui/src/tokens/pos_dimens.dart';
import 'package:pos_ui/src/tokens/pos_palette.dart';
import 'package:pos_ui/src/tokens/pos_typography.dart';

/// Navigatsiya bo'limi.
class PosDestination {
  const PosDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.shortcut,
    this.badgeCount,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  /// Yon panelda ko'rinadigan tezkor tugma yorlig'i (desktop).
  final String? shortcut;

  /// Ikon ustidagi son (masalan, kam qolgan tovarlar). 0 yoki `null` — yo'q.
  final int? badgeCount;
}

/// Ilova karkasi, ekran kengligiga moslashadi:
/// - compact (< 600): holat qatori tepada, pastda navigatsiya paneli;
/// - medium (600–899): chapda ixcham rels (ikon + yozuv), holat qatori pastda;
/// - expanded (≥ 900): chapda 240 dp yon panel (yozuv + tezkor tugma).
class PosResponsiveScaffold extends StatelessWidget {
  const PosResponsiveScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.statusBar,
    this.header,
    this.footer,
    super.key,
  }) : assert(destinations.length >= 2, 'Kamida 2 bo‘lim');

  final List<PosDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Odatda `PosStatusBar`; joylashuvi o'lchamga qarab tanlanadi.
  final Widget? statusBar;

  /// Yon panel tepasi (logo, do'kon nomi) — faqat expanded.
  final Widget? header;

  /// Yon panel pasti (kassir, sozlamalar) — faqat expanded.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final size = PosWindowSize.of(context);

    if (size.isCompact) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ?statusBar,
              Expanded(child: body),
            ],
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelBehavior: destinations.length > 5
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: _withBadge(context, Icon(d.icon), d.badgeCount),
                  selectedIcon: _withBadge(
                    context,
                    Icon(d.selectedIcon ?? d.icon),
                    d.badgeCount,
                  ),
                  label: d.label,
                  tooltip: d.label,
                ),
            ],
          ),
        ),
      );
    }

    final nav = size.isExpandedUp
        ? _SideNav(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: onDestinationSelected,
            header: header,
            footer: footer,
          )
        : _Rail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: onDestinationSelected,
          );

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: Border(right: BorderSide(color: p.border)),
                  ),
                  child: SafeArea(right: false, child: nav),
                ),
                Expanded(child: SafeArea(left: false, child: body)),
              ],
            ),
          ),
          ?statusBar,
        ],
      ),
    );
  }
}

Widget _withBadge(BuildContext context, Widget icon, int? count) {
  if (count == null || count <= 0) return icon;
  final p = PosPalette.of(context);
  return Badge(
    label: Text(count > 99 ? '99+' : '$count'),
    backgroundColor: p.danger,
    textColor: p.onDanger,
    textStyle: PosTypography.caption.copyWith(fontWeight: FontWeight.w600),
    child: icon,
  );
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.header,
    this.footer,
  });

  final List<PosDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PosSizes.sideNavWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PosSpacing.l,
                PosSpacing.l,
                PosSpacing.l,
                PosSpacing.s,
              ),
              child: header,
            ),
          Expanded(
            child: FocusTraversalGroup(
              child: ListView(
                padding: const EdgeInsets.all(PosSpacing.m),
                children: [
                  for (final (i, d) in destinations.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: PosSpacing.xs),
                      child: _SideNavItem(
                        destination: d,
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.all(PosSpacing.m),
              child: footer,
            ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final PosDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final fg = selected ? p.onPrimarySoft : p.textSecondary;
    final count = destination.badgeCount ?? 0;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? p.primarySoft : Colors.transparent,
        borderRadius: PosRadius.controlAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: p.text.withValues(alpha: 0.04),
          focusColor: p.primary.withValues(alpha: 0.12),
          child: SizedBox(
            height: PosSizes.touchMin,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PosSpacing.m),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? destination.selectedIcon ?? destination.icon
                        : destination.icon,
                    color: fg,
                    size: PosSizes.iconL,
                  ),
                  const SizedBox(width: PosSpacing.m),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PosTypography.body.copyWith(
                        color: selected ? p.onPrimarySoft : p.text,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (count > 0) ...[
                    _CountPill(count: count),
                    const SizedBox(width: PosSpacing.s),
                  ],
                  if (destination.shortcut != null)
                    PosKeycap(label: destination.shortcut!, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: p.danger,
        borderRadius: PosRadius.pillAll,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: PosTypography.caption.copyWith(
          color: p.onDanger,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PosDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return SizedBox(
      width: PosSizes.railWidth,
      child: FocusTraversalGroup(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: PosSpacing.m),
          children: [
            for (final (i, d) in destinations.indexed)
              Semantics(
                selected: i == selectedIndex,
                child: InkWell(
                  onTap: () => onSelected(i),
                  hoverColor: p.text.withValues(alpha: 0.04),
                  focusColor: p.primary.withValues(alpha: 0.12),
                  child: SizedBox(
                    height: 72,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: PosMotion.press,
                          width: 56,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == selectedIndex
                                ? p.primarySoft
                                : Colors.transparent,
                            borderRadius: PosRadius.pillAll,
                          ),
                          child: _withBadge(
                            context,
                            Icon(
                              i == selectedIndex
                                  ? d.selectedIcon ?? d.icon
                                  : d.icon,
                              color: i == selectedIndex
                                  ? p.onPrimarySoft
                                  : p.textSecondary,
                            ),
                            d.badgeCount,
                          ),
                        ),
                        const SizedBox(height: PosSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: PosSpacing.xs,
                          ),
                          child: Text(
                            d.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PosTypography.caption.copyWith(
                              color: i == selectedIndex
                                  ? p.onPrimarySoft
                                  : p.textSecondary,
                              fontWeight: i == selectedIndex
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
