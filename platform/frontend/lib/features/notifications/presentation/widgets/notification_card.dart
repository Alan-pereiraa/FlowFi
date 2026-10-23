import 'package:material_ui/material_ui.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  static const _subjectIcons = {
    'category_limit_warning': Icons.data_usage,
    'installment_due_soon': Icons.payments_outlined,
    'installment_overdue': Icons.event_busy,
    'goal_deadline': Icons.savings,
    'recurring_transaction_skipped': Icons.event_repeat,
    'recurring_transaction_ended': Icons.repeat,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<AppColors>()!;
    final unread = !notification.isRead;

    final accent = switch (notification.type) {
      NotificationType.info => colors.info,
      NotificationType.success => colors.success,
      NotificationType.warning => colors.warning,
      NotificationType.error => scheme.error,
    };
    final icon =
        _subjectIcons[notification.subject] ??
        switch (notification.type) {
          NotificationType.info => Icons.info_outline,
          NotificationType.success => Icons.check_circle_outline,
          NotificationType.warning => Icons.warning_amber_rounded,
          NotificationType.error => Icons.error_outline,
        };

    return Semantics(
      container: true,
      button: onTap != null && unread,
      excludeSemantics: true,
      label:
          '${unread ? 'Não lida. ' : ''}${notification.title}. '
          '${notification.message}',
      onTap: unread ? onTap : null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (unread)
                Positioned(
                  top: -48,
                  right: -48,
                  child: IgnorePointer(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.14),
                            accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: accent.withValues(alpha: 0.16),
                              foregroundColor: accent,
                              child: Icon(icon, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                color: scheme.onSurface,
                                                fontWeight: unread
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      if (unread) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: unread
                                          ? scheme.onSurface
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
