import 'package:flowfi_app/core/clock.dart';
import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/paginated.dart';
import 'package:flowfi_app/features/notifications/data/models/notification_dto.dart';
import 'package:flowfi_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:flowfi_app/features/notifications/domain/entities/app_notification.dart';
import 'package:flowfi_app/features/notifications/domain/entities/notification_filter.dart';
import 'package:flowfi_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:flowfi_app/features/notifications/presentation/controllers/notification_list_controller.dart';
import 'package:flowfi_app/features/notifications/presentation/controllers/unread_count_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class _MockRepository extends Mock implements NotificationRepository {}

class _FakeUnreadCount extends UnreadCountController {
  int refreshes = 0;

  @override
  int build() => 0;

  @override
  Future<void> refresh() async => refreshes++;
}

AppNotification _item(int id, {String? readAt}) =>
    NotificationDto.fromJson(notificationJson(id: id, readAt: readAt))
        .toEntity();

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.list(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Paginated(
        items: [
          _item(3),
          _item(2),
          _item(1, readAt: '2026-10-22T13:00:00Z'),
        ],
        currentPage: 1,
        lastPage: 1,
        total: 3,
      ),
    );
    when(() => repository.unreadCount()).thenAnswer((_) async => 2);
  });

  Future<ProviderContainer> boot() async {
    final container = ProviderContainer.test(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 23)),
        unreadCountControllerProvider.overrideWith(_FakeUnreadCount.new),
      ],
    );
    container.listen(notificationListControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  test('loads the newest page', () async {
    final container = await boot();
    final state = container.read(notificationListControllerProvider);

    expect(state.loaded, isTrue);
    expect(state.items.map((n) => n.id), [3, 2, 1]);
    expect(state.hasMore, isFalse);
  });

  test('marks as read', () async {
    when(() => repository.markAsRead(3))
        .thenAnswer((_) async => _item(3, readAt: '2026-10-23T10:00:00Z'));
    final container = await boot();

    final error = await container
        .read(notificationListControllerProvider.notifier)
        .markAsRead(3);

    expect(error, isNull);
    expect(
      container.read(notificationListControllerProvider).items.first.isRead,
      isTrue,
    );
  });

  test('a failed mark as read is rolled back', () async {
    when(() => repository.markAsRead(3)).thenThrow(const NetworkFailure());
    final container = await boot();

    final error = await container
        .read(notificationListControllerProvider.notifier)
        .markAsRead(3);

    expect(error, contains('Sem conexão'));
    expect(
      container.read(notificationListControllerProvider).items.first.isRead,
      isFalse,
    );
  });

  test('changing the filter reloads with that status', () async {
    when(
      () => repository.list(
        filter: NotificationFilter.unread,
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Paginated(
        items: [_item(3), _item(2)],
        currentPage: 1,
        lastPage: 1,
        total: 2,
      ),
    );
    final container = await boot();

    await container
        .read(notificationListControllerProvider.notifier)
        .setFilter(NotificationFilter.unread);

    final state = container.read(notificationListControllerProvider);
    expect(state.filter, NotificationFilter.unread);
    expect(state.items.map((n) => n.id), [3, 2]);
  });

  test('marks all as read', () async {
    when(() => repository.markAllAsRead()).thenAnswer((_) async {});
    final container = await boot();

    final error = await container
        .read(notificationListControllerProvider.notifier)
        .markAllAsRead();

    expect(error, isNull);
    expect(
      container
          .read(notificationListControllerProvider)
          .items
          .every((n) => n.isRead),
      isTrue,
    );
    verify(() => repository.markAllAsRead()).called(1);
  });

  test('a failed mark all as read is rolled back', () async {
    when(() => repository.markAllAsRead()).thenThrow(const NetworkFailure());
    final container = await boot();

    final error = await container
        .read(notificationListControllerProvider.notifier)
        .markAllAsRead();

    expect(error, contains('Sem conexão'));
    expect(
      container
          .read(notificationListControllerProvider)
          .items
          .map((n) => n.isRead),
      [false, false, true],
    );
  });

  test('delete removes the item, a failure puts it back', () async {
    when(() => repository.delete(2)).thenAnswer((_) async {});
    when(() => repository.delete(3)).thenThrow(const UnexpectedFailure());
    final container = await boot();
    final controller = container.read(
      notificationListControllerProvider.notifier,
    );

    expect(await controller.delete(2), isNull);
    expect(
      container.read(notificationListControllerProvider).items.map((n) => n.id),
      [3, 1],
    );

    expect(await controller.delete(3), isNotNull);
    expect(
      container.read(notificationListControllerProvider).items.map((n) => n.id),
      [3, 1],
    );
  });
}
