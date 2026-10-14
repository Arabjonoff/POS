import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/app/shell/app_sections.dart';
import 'package:pos_app/app/shell/app_shell.dart';
import 'package:pos_app/features/auth/lock_screen.dart';
import 'package:pos_app/features/auth/setup_screen.dart';
import 'package:pos_app/features/common/section_page.dart';
import 'package:pos_app/features/pos/pos_screen.dart';
import 'package:pos_app/features/products/products_screen.dart';
import 'package:pos_app/features/receiving/receiving_screen.dart';
import 'package:pos_app/features/settings/settings_screen.dart';
import 'package:pos_app/features/shift/shift_screen.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';

abstract final class AppRoutes {
  static final String pos = AppSection.pos.path;
  static const String setup = '/setup';
  static const String lock = '/lock';
}

Widget _comingSoon(BuildContext context, AppSection section) => ComingSoonPage(
  title: section.label(AppLocalizations.of(context)),
  icon: section.icon,
);

/// Sessiya bosqichiga qarab: ulash → qulf (PIN) → kassa. PIN'dan keyin
/// darhol kassa ekrani (CLAUDE.md).
String? _redirect(SessionStage stage, String location) => switch (stage) {
  SessionStage.setup || SessionStage.initialSync =>
    location == AppRoutes.setup ? null : AppRoutes.setup,
  SessionStage.locked => location == AppRoutes.lock ? null : AppRoutes.lock,
  SessionStage.unlocked =>
    location == AppRoutes.setup || location == AppRoutes.lock
        ? AppRoutes.pos
        : null,
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (previous, next) {
      // Faqat bosqich o'zgarsa (masalan, boshqa xodim kirsa ham).
      if (previous?.stage != next.stage || previous?.user != next.user) {
        refresh.value++;
      }
    })
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.pos,
    refreshListenable: refresh,
    redirect: (context, state) =>
        _redirect(ref.read(sessionProvider).stage, state.matchedLocation),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.pos),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.lock,
        builder: (context, state) => const LockScreen(),
      ),
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
                    AppSection.products => const ProductsScreen(),
                    AppSection.receiving => const ReceivingScreen(),
                    AppSection.settings => const SettingsScreen(),
                    _ => _comingSoon(context, section),
                  },
                  routes: [
                    if (section == AppSection.pos)
                      GoRoute(
                        path: 'shift',
                        builder: (context, state) => const ShiftScreen(),
                      ),
                  ],
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
