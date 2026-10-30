import '../../../../core/network/paginated.dart';
import '../entities/app_notification.dart';
import '../entities/notification_filter.dart';

abstract interface class NotificationRepository {
  Future<Paginated<AppNotification>> list({
    NotificationFilter filter = NotificationFilter.all,
    int page = 1,
    int perPage = 20,
  });

  Future<int> unreadCount();

  Future<AppNotification> markAsRead(int id);

  Future<void> markAllAsRead();

  Future<void> delete(int id);
}
