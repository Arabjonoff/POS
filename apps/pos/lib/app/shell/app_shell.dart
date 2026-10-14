import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/shell/app_sections.dart';
import 'package:pos_app/app/shell/app_status_bar.dart';
import 'package:pos_app/features/auth/lock_screen.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Ilova qobig'i: navigatsiya (telefonda pastda, planshet/desktopda chapda),
/// holat qatori va bo'lim sahifasi. Bo'limlar holati saqlanadi
/// (`StatefulShellRoute.indexedStack`).
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
    index,
    // Tanlangan bo'limni qayta bosish — bo'lim boshiga qaytish.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final user = ref.watch(sessionProvider).user;
    return CallbackShortcuts(
      bindings: {
        for (final section in AppSection.values)
          section.shortcut: () => _go(section.index),
      },
      child: Focus(
        autofocus: true,
        child: PosResponsiveScaffold(
          destinations: [
            for (final section in AppSection.values) section.destination(l10n),
          ],
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _go,
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
                    onPressed: () => ref.read(sessionProvider.notifier).lock(),
                  ),
                ),
          body: navigationShell,
        ),
      ),
    );
  }
}
