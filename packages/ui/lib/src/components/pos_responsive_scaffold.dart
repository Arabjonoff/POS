import 'dart:async';

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
/// - expanded (≥ 900): chapda 240 dp yon panel (yozuv + tezkor tugma) yoki,
///   [onNavExpandedChanged] berilsa, 64 dp yig'ilgan menyu: sichqoncha olib
///   borilsa kontent ustida ochiladi, [navExpanded] — doim ochiq (kontent
///   suriladi).
class PosResponsiveScaffold extends StatelessWidget {
  const PosResponsiveScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.statusBar,
    this.header,
    this.footer,
    this.railFooter,
    this.navExpanded = false,
    this.onNavExpandedChanged,
    this.expandNavTooltip = '',
    this.collapseNavTooltip = '',
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

  /// Yig'ilgan menyu pasti (64 dp: kassir bosh harfi, qulf).
  final Widget? railFooter;

  /// Yig'iladigan menyu doim ochiqmi (Ctrl+B).
  final bool navExpanded;

  /// Berilsa — desktopda yig'iladigan menyu; ochish/yig'ish tugmasi chaqiradi.
  final ValueChanged<bool>? onNavExpandedChanged;
  final String expandNavTooltip;
  final String collapseNavTooltip;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final size = PosWindowSize.of(context);
    final onToggle = onNavExpandedChanged;

    if (size.isExpandedUp && onToggle != null) {
      final inset = navExpanded
          ? PosSizes.sideNavWidth
          : PosSizes.navCollapsedWidth;
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    left: inset,
                    child: SafeArea(left: false, child: body),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: SafeArea(
                      right: false,
                      child: _CollapsibleNav(
                        destinations: destinations,
                        selectedIndex: selectedIndex,
                        onSelected: onDestinationSelected,
                        pinned: navExpanded,
                        onToggle: () => onToggle(!navExpanded),
                        expandTooltip: expandNavTooltip,
                        collapseTooltip: collapseNavTooltip,
                        header: header,
                        footer: footer,
                        railFooter: railFooter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ?statusBar,
          ],
        ),
      );
    }

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
        bottomNavigationBar: _BottomNav(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onSelected: onDestinationSelected,
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

/// Desktop yig'iladigan menyu: 64 dp ikonlar; sichqoncha olib borilsa
/// (300 ms kutib) yoki [pinned] — 240 dp, yozuv va tezkor tugmalar bilan.
class _CollapsibleNav extends StatefulWidget {
  const _CollapsibleNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.pinned,
    required this.onToggle,
    required this.expandTooltip,
    required this.collapseTooltip,
    this.header,
    this.footer,
    this.railFooter,
  });

  final List<PosDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool pinned;
  final VoidCallback onToggle;
  final String expandTooltip;
  final String collapseTooltip;
  final Widget? header;
  final Widget? footer;
  final Widget? railFooter;

  /// Sichqoncha tasodifan o'tib ketganda ochilib-yopilmasin.
  static const Duration hoverDelay = Duration(milliseconds: 300);

  @override
  State<_CollapsibleNav> createState() => _CollapsibleNavState();
}

class _CollapsibleNavState extends State<_CollapsibleNav> {
  bool _hover = false;
  Timer? _timer;

  @override
  void didUpdateWidget(_CollapsibleNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Yig'ish tugmasi bosildi — sichqoncha ustida bo'lsa ham yopilsin.
    if (oldWidget.pinned && !widget.pinned) _close();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _enter() {
    _timer?.cancel();
    _timer = Timer(_CollapsibleNav.hoverDelay, () {
      if (mounted) setState(() => _hover = true);
    });
  }

  void _close() {
    _timer?.cancel();
    if (_hover) setState(() => _hover = false);
  }

  void _select(int index) {
    _close();
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final open = widget.pinned || _hover;
    // Ustiga chiqqan (vaqtincha) menyu — soya bilan.
    final floating = _hover && !widget.pinned;
    return MouseRegion(
      onEnter: (_) => _enter(),
      onExit: (_) => _close(),
      child: AnimatedContainer(
        duration: PosMotion.overlay,
        curve: PosMotion.curve,
        width: open ? PosSizes.sideNavWidth : PosSizes.navCollapsedWidth,
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(right: BorderSide(color: p.border)),
          boxShadow: floating ? p.overlayShadow : null,
        ),
        child: LayoutBuilder(
          // Ochilish paytida (oraliq kenglikda) — ixcham ko'rinish.
          builder: (context, constraints) =>
              constraints.maxWidth >= PosSizes.sideNavWidth - 1
              ? _wide()
              : _narrow(),
        ),
      ),
    );
  }

  Widget _wide() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          PosSpacing.l,
          PosSpacing.s,
          PosSpacing.s,
          PosSpacing.s,
        ),
        child: Row(
          children: [
            Expanded(child: widget.header ?? const SizedBox.shrink()),
            _NavToggle(
              tooltip: widget.pinned
                  ? widget.collapseTooltip
                  : widget.expandTooltip,
              pinned: widget.pinned,
              onPressed: widget.onToggle,
            ),
          ],
        ),
      ),
      Expanded(
        child: FocusTraversalGroup(
          child: ListView(
            padding: const EdgeInsets.all(PosSpacing.m),
            children: [
              for (final (i, d) in widget.destinations.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: PosSpacing.xs),
                  child: _SideNavItem(
                    destination: d,
                    selected: i == widget.selectedIndex,
                    onTap: () => _select(i),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (widget.footer != null)
        Padding(
          padding: const EdgeInsets.all(PosSpacing.m),
          child: widget.footer,
        ),
    ],
  );

  Widget _narrow() {
    final p = PosPalette.of(context);
    return Column(
      children: [
        const SizedBox(height: PosSpacing.s),
        _NavToggle(
          tooltip: widget.expandTooltip,
          pinned: false,
          onPressed: widget.onToggle,
        ),
        Container(
          width: 32,
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
          color: p.border,
        ),
        Expanded(
          child: FocusTraversalGroup(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: PosSpacing.xs),
              children: [
                for (final (i, d) in widget.destinations.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: PosSpacing.xs),
                    child: _IconNavItem(
                      destination: d,
                      selected: i == widget.selectedIndex,
                      onTap: () => _select(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.railFooter != null)
          Padding(
            padding: const EdgeInsets.only(bottom: PosSpacing.s),
            child: widget.railFooter,
          ),
      ],
    );
  }
}

/// Menyuni ochish/yig'ish tugmasi (48 × 48).
class _NavToggle extends StatelessWidget {
  const _NavToggle({
    required this.tooltip,
    required this.pinned,
    required this.onPressed,
  });

  final String tooltip;
  final bool pinned;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey('nav-toggle'),
            onTap: onPressed,
            borderRadius: PosRadius.controlAll,
            hoverColor: p.text.withValues(alpha: 0.04),
            focusColor: p.primary.withValues(alpha: 0.12),
            child: SizedBox.square(
              dimension: PosSizes.touchMin,
              child: Icon(
                pinned
                    ? Icons.keyboard_double_arrow_left
                    : Icons.keyboard_double_arrow_right,
                color: p.textSecondary,
                size: PosSizes.iconL,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yig'ilgan menyu elementi: 48 × 48 ikon; yozuv va tezkor tugma — tooltip.
class _IconNavItem extends StatelessWidget {
  const _IconNavItem({
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
    final shortcut = destination.shortcut;
    final tip = shortcut == null
        ? destination.label
        : '${destination.label} · $shortcut';
    return Center(
      child: Semantics(
        selected: selected,
        button: true,
        label: destination.label,
        excludeSemantics: true,
        child: Tooltip(
          message: tip,
          excludeFromSemantics: true,
          child: Material(
            color: selected ? p.primarySoft : Colors.transparent,
            borderRadius: PosRadius.controlAll,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              hoverColor: p.text.withValues(alpha: 0.04),
              focusColor: p.primary.withValues(alpha: 0.12),
              child: SizedBox.square(
                dimension: PosSizes.touchMin,
                child: Center(
                  child: _withBadge(
                    context,
                    Icon(
                      selected
                          ? destination.selectedIcon ?? destination.icon
                          : destination.icon,
                      color: fg,
                      size: PosSizes.iconL,
                    ),
                    destination.badgeCount,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    return SizedBox(
      width: PosSizes.railWidth,
      child: FocusTraversalGroup(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: PosSpacing.m),
          children: [
            for (final (i, d) in destinations.indexed)
              SizedBox(
                height: 72,
                child: _NavTile(
                  destination: d,
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Telefon: pastki navigatsiya paneli. Yorliqlar doim ko'rinadi va bir
/// qatorda (6 bo'limda ham — joy yetmasa shrift kichrayadi).
class _BottomNav extends StatelessWidget {
  const _BottomNav({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final (i, d) in destinations.indexed)
                Expanded(
                  child: _NavTile(
                    destination: d,
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                    // 5 tadan ko'p bo'limda yozuvlar siqilib, kesilardi
                    // ("Настройки") — faqat tanlanganning yozuvi.
                    showLabel: destinations.length <= 5 || i == selectedIndex,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rels va pastki panel elementi: ikon (tanlanganda yumshoq fon) + yorliq.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.showLabel = true,
  });

  final PosDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final fg = selected ? p.onPrimarySoft : p.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          hoverColor: p.text.withValues(alpha: 0.04),
          focusColor: p.primary.withValues(alpha: 0.12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: PosMotion.press,
                width: 56,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? p.primarySoft : Colors.transparent,
                  borderRadius: PosRadius.pillAll,
                ),
                child: _withBadge(
                  context,
                  Icon(
                    selected
                        ? destination.selectedIcon ?? destination.icon
                        : destination.icon,
                    color: fg,
                  ),
                  destination.badgeCount,
                ),
              ),
              if (showLabel) ...[
                const SizedBox(height: PosSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      style: PosTypography.caption.copyWith(
                        color: fg,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
