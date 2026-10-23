import '../../../../core/network/paginated.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationRepository {
  Future<Paginated<AppNotification>> list({int page = 1, int perPage = 20});

  Future<int> unreadCount();

  Future<AppNotification> markAsRead(int id);

  Future<void> delete(int id);
}
