import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../shared/layout/breakpoints.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_filter.dart';
import '../controllers/notification_list_controller.dart';
import '../controllers/unread_count_controller.dart';
import '../widgets/notification_card.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) {
      ref.read(notificationListControllerProvider.notifier).loadMore();
    }
  }

  void _showError(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _markAsRead(AppNotification notification) async {
    _showError(
      await ref
          .read(notificationListControllerProvider.notifier)
          .markAsRead(notification.id),
    );
  }

  Future<void> _markAllAsRead() async {
    _showError(
      await ref
          .read(notificationListControllerProvider.notifier)
          .markAllAsRead(),
    );
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir notificação?'),
        content: const Text('Ela deixa de aparecer na sua lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _delete(AppNotification notification) async {
    _showError(
      await ref
          .read(notificationListControllerProvider.notifier)
          .delete(notification.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListControllerProvider);
    final controller = ref.read(notificationListControllerProvider.notifier);

    final Widget body;
    if (state.showSpinner) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.showError) {
      body = _ErrorPanel(
        message: state.errorMessage!,
        onRetry: controller.refresh,
      );
    } else if (state.items.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          switch (state.filter) {
            NotificationFilter.all => const EmptyState(
              icon: Icons.notifications_none,
              title: 'Nenhuma notificação',
              message: 'Avisos sobre limites, parcelas e metas aparecem aqui.',
            ),
            NotificationFilter.unread => const EmptyState(
              icon: Icons.done_all,
              title: 'Tudo em dia',
              message: 'Você não tem notificações não lidas.',
            ),
            NotificationFilter.read => const EmptyState(
              icon: Icons.notifications_none,
              title: 'Nenhuma notificação lida',
            ),
          },
        ],
      );
    } else {
      body = ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.items.length + (state.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = state.items[index];
          return ResponsiveCenter(
            maxWidth: Breakpoints.formMax + 160,
            child: Padding(
              padding: EdgeInsets.only(top: index == 0 ? 8 : 0, bottom: 16),
              child: Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(),
                onDismissed: (_) => _delete(item),
                background: _DeleteBackground(),
                child: NotificationCard(
                  notification: item,
                  onTap: () => _markAsRead(item),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        leadingWidth: 64,
        leading: const AppBackButton(fallbackRoute: Routes.dashboard),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como lidas',
            icon: const Icon(Icons.done_all),
            // The badge count covers unread items the current filter hides.
            onPressed:
                ref.watch(unreadCountControllerProvider) > 0 ||
                    state.items.any((item) => !item.isRead)
                ? _markAllAsRead
                : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FilterChips(
              selected: state.filter,
              onSelected: controller.setFilter,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Todas / Não lidas / Lidas", styled like the transactions filter chips.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          for (final filter in NotificationFilter.values) ...[
            if (filter != NotificationFilter.values.first)
              const SizedBox(width: 8),
            FilterChip(
              showCheckmark: false,
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
              label: Text(filter.label),
              shape: const StadiumBorder(),
              side: BorderSide.none,
              backgroundColor: scheme.surfaceContainerHigh,
              selectedColor: scheme.primary,
              labelStyle: TextStyle(
                color: filter == selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Excluir',
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 240,
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
      ],
    );
  }
}
