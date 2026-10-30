import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paginated.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notifications_api.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(ref.watch(notificationsApiProvider)),
);

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._api);

  final NotificationsApi _api;

  @override
  Future<Paginated<AppNotification>> list({
    int page = 1,
    int perPage = 20,
  }) async {
    final dtos = await guardApi(() => _api.list(page: page, perPage: perPage));
    return dtos.map((dto) => dto.toEntity());
  }

  @override
  Future<int> unreadCount() async {
    final page = await guardApi(
      () => _api.list(status: 'unread', page: 1, perPage: 1),
    );
    return page.total;
  }

  @override
  Future<AppNotification> markAsRead(int id) async {
    final dto = await guardApi(() => _api.markAsRead(id));
    return dto.toEntity();
  }

  @override
  Future<void> delete(int id) => guardApi(() => _api.delete(id));
}
