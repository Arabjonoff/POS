import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_app/features/pos/pos_screen.dart';

abstract final class AppRoutes {
  static const String pos = '/';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.pos,
    routes: [
      GoRoute(
        path: AppRoutes.pos,
        builder: (context, state) => const PosScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
