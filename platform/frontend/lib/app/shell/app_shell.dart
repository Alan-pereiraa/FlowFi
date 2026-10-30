import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../features/identity/presentation/controllers/session_controller.dart';
import '../../features/notifications/presentation/controllers/unread_count_controller.dart';
import '../../shared/widgets/app_logo.dart';
import '../routes.dart';

/// Authenticated layout: shared top bar + four-tab bottom bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _dashboardIndex = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final unread = ref.watch(unreadCountControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            tooltip: 'Perfil',
            onPressed: () => context.push(Routes.editProfile),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: Text(
                user?.initials ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        title: const AppLogo(size: 22),
        actions: [
          IconButton(
            tooltip: unread > 0
                ? 'Notificações, $unread não lidas'
                : 'Notificações',
            onPressed: () async {
              await context.push(Routes.notifications);
              ref.read(unreadCountControllerProvider.notifier).refresh();
            },
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index == _dashboardIndex &&
              index != navigationShell.currentIndex) {
            ref.read(dashboardControllerProvider.notifier).load();
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transações',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorias',
          ),
        ],
      ),
    );
  }
}
