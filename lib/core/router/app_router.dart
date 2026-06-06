import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/preview/presentation/preview_page.dart';
import '../../features/settings/presentation/api_config_page.dart';
import '../../features/settings/presentation/credits_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/workspace/presentation/workspace_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;

  ref.listen(authProvider, (_, _) {
    router.refresh();
  });

  router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthPage()),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(
        path: '/project/:id/workspace',
        builder: (_, state) =>
            WorkspacePage(projectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/project/:id/preview',
        builder: (_, state) =>
            PreviewPage(projectId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings/api', builder: (_, _) => const ApiConfigPage()),
      GoRoute(
        path: '/settings/credits',
        builder: (_, _) => const CreditsPage(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.initial;
      final location = state.matchedLocation;

      if (isLoading) {
        return null;
      }
      if (!isLoggedIn && location != '/auth') {
        return '/auth';
      }
      if (isLoggedIn && (location == '/auth' || location == '/splash')) {
        return '/home';
      }
      return null;
    },
  );

  ref.onDispose(router.dispose);
  return router;
});
