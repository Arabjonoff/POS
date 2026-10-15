import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/shell/app_sections.dart';
import 'package:pos_app/app/shell/app_status_bar.dart';
import 'package:pos_app/app/shell/subscription_banner.dart';
import 'package:pos_app/features/auth/lock_screen.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Ilova qobig'i: navigatsiya (telefonda pastda, planshetda rels, desktopda
/// 64 dp yig'ilgan menyu — sichqoncha yoki Ctrl+B ochadi), holat qatori va
/// bo'lim sahifasi. Bo'limlar holati saqlanadi
/// (`StatefulShellRoute.indexedStack`).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Menyuni doim ochiq qilish/yig'ish.
  static const SingleActivator toggleNav = SingleActivator(
    LogicalKeyboardKey.keyB,
    control: true,
  );

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _navExpanded = false;

  StatefulNavigationShell get _shell => widget.navigationShell;

  void _go(int index) => _shell.goBranch(
    index,
    // Tanlangan bo'limni qayta bosish — bo'lim boshiga qaytish.
    initialLocation: index == _shell.currentIndex,
  );

  void _toggleNav() => setState(() => _navExpanded = !_navExpanded);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final user = ref.watch(sessionProvider).user;
    void lock() => ref.read(sessionProvider.notifier).lock();
    return CallbackShortcuts(
      bindings: {
        for (final section in AppSection.values)
          section.shortcut: () => _go(section.index),
        AppShell.toggleNav: _toggleNav,
      },
      child: Focus(
        autofocus: true,
        child: PosResponsiveScaffold(
          destinations: [
            for (final section in AppSection.values) section.destination(l10n),
          ],
          selectedIndex: _shell.currentIndex,
          onDestinationSelected: _go,
          navExpanded: _navExpanded,
          onNavExpandedChanged: (v) => setState(() => _navExpanded = v),
          expandNavTooltip: l10n.navExpand,
          collapseNavTooltip: l10n.navCollapse,
          statusBar: const AppStatusBar(),
          header: Row(
            children: [
              Icon(Icons.storefront, color: p.primaryText),
              const SizedBox(width: PosSpacing.s),
              Expanded(
                child: Text(
                  l10n.appTitle,
                  overflow: TextOverflow.ellipsis,
                  style: PosTypography.h3.copyWith(color: p.text),
                ),
              ),
            ],
          ),
          footer: user == null
              ? null
              : PosListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: user.fullName,
                  subtitle: roleLabel(l10n, user.role),
                  padding: const EdgeInsets.only(left: PosSpacing.s),
                  trailing: PosIconButton(
                    icon: Icons.lock_outline,
                    tooltip: l10n.actionLock,
                    onPressed: lock,
                  ),
                ),
          railFooter: user == null
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message:
                          '${user.fullName} · ${roleLabel(l10n, user.role)}',
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: p.surfaceMuted,
                        child: Text(
                          user.fullName.trim().isEmpty
                              ? '?'
                              : user.fullName.trim().characters.first
                                    .toUpperCase(),
                          style: PosTypography.bodyStrong.copyWith(
                            color: p.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: PosSpacing.xs),
                    PosIconButton(
                      key: const ValueKey('rail-lock'),
                      icon: Icons.lock_outline,
                      tooltip: l10n.actionLock,
                      onPressed: lock,
                    ),
                  ],
                ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SubscriptionBanner(),
              Expanded(child: _shell),
            ],
          ),
        ),
      ),
    );
  }
}
