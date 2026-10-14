import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/shell/app_sections.dart';
import 'package:pos_app/app/shell/app_shell.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/pos/pos_screen.dart';
import 'package:pos_app/features/settings/settings_screen.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

abstract final class AppRoutes {
  static final String pos = AppSection.pos.path;
}

Widget _comingSoon(BuildContext context, AppSection section) => ComingSoonPage(
  title: section.label(AppLocalizations.of(context)),
  icon: section.icon,
);

/// Marshrutlar: ochilganda darhol kassa (CLAUDE.md). PIN/kirish — T-034.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.pos,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.pos),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          for (final section in AppSection.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: section.path,
                  builder: (context, state) => switch (section) {
                    AppSection.pos => const PosScreen(),
                    AppSection.settings => const SettingsScreen(),
                    _ => _comingSoon(context, section),
                  },
                ),
              ],
            ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
