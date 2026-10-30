import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/categories/presentation/categories_routes.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/goals/presentation/goals_route.dart';
import '../features/identity/presentation/controllers/session_controller.dart';
import '../features/identity/presentation/controllers/session_state.dart';
import '../features/identity/presentation/pages/login_page.dart';
import '../features/identity/presentation/pages/profile_form_page.dart';
import '../features/identity/presentation/pages/profile_success_page.dart';
import '../features/identity/presentation/pages/splash_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/transactions/presentation/pages/transaction_form_page.dart';
import '../features/transactions/presentation/pages/transactions_page.dart';
import 'routes.dart';
import 'shell/app_shell.dart';

/// Every auth redirect, derived from session state only. Navigation after
/// login/logout is never imperative.
String? redirectFor(SessionState session, String location) {
  return switch (session) {
    SessionUnknown() => location == Routes.splash ? null : Routes.splash,
    SessionUnauthenticated() => location == Routes.login ? null : Routes.login,
    SessionNeedsProfile() =>
      location == Routes.completeProfile ? null : Routes.completeProfile,
    // Only reachable right after the first-login form is saved.
    SessionAuthenticated() when location == Routes.completeProfile =>
      Routes.profileSuccess,
    SessionAuthenticated()
        when location == Routes.splash || location == Routes.login =>
      Routes.dashboard,
    SessionAuthenticated() => null,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<SessionState>(
    ref.read(sessionControllerProvider),
  );
  ref.listen(sessionControllerProvider, (_, next) => session.value = next);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (context, state) =>
        redirectFor(session.value, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: Routes.completeProfile,
        builder: (_, _) =>
            const ProfileFormPage(mode: ProfileFormMode.complete),
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (_, _) => const ProfileFormPage(mode: ProfileFormMode.edit),
      ),
      GoRoute(
        path: Routes.profileSuccess,
        builder: (_, _) => const ProfileSuccessPage(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      ...categoryFormRoutes(),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (_, _) => const DashboardPage(),
                routes: [
                  GoRoute(
                    path: 'new-transaction',
                    builder: (_, _) => const TransactionFormPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.transactions,
                builder: (_, _) => const TransactionsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const TransactionFormPage(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (_, state) => TransactionFormPage(
                      transactionId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(routes: [goalsRoute()]),
          StatefulShellBranch(routes: [categoriesRoute()]),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
