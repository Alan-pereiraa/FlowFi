import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/api_exception.dart';
import 'package:flowfi_app/core/network/paginated.dart';
import 'package:flowfi_app/features/notifications/data/datasources/notifications_api.dart';
import 'package:flowfi_app/features/notifications/data/models/notification_dto.dart';
import 'package:flowfi_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:flowfi_app/features/notifications/domain/entities/notification_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class _MockApi extends Mock implements NotificationsApi {}

void main() {
  late _MockApi api;
  late NotificationRepositoryImpl repository;

  setUp(() {
    api = _MockApi();
    repository = NotificationRepositoryImpl(api);
  });

  test('parses the resource', () {
    final read = NotificationDto.fromJson(
      notificationJson(type: 'error', readAt: '2026-10-22T13:00:00.000000Z'),
    ).toEntity();
    final unknown = NotificationDto.fromJson(
      notificationJson(type: 'something-new'),
    ).toEntity();

    expect(read.type, NotificationType.error);
    expect(read.isRead, isTrue);
    expect(read.subject, 'category_limit_warning');
    expect(read.createdAt.toUtc(), DateTime.utc(2026, 10, 22, 12));
    expect(unknown.type, NotificationType.info);
    expect(unknown.isRead, isFalse);
  });

  test('unread count reads meta.total of one unread item', () async {
    when(() => api.list(status: 'unread', page: 1, perPage: 1)).thenAnswer(
      (_) async => Paginated(
        items: [NotificationDto.fromJson(notificationJson())],
        currentPage: 1,
        lastPage: 7,
        total: 7,
      ),
    );

    expect(await repository.unreadCount(), 7);
  });

  final cases = <int?, Matcher>{
    404: isA<NotFoundFailure>(),
    null: isA<NetworkFailure>(),
    500: isA<UnexpectedFailure>(),
  };
  for (final MapEntry(key: status, value: matcher) in cases.entries) {
    test('HTTP $status → $matcher', () async {
      when(() => api.delete(1)).thenThrow(ApiException(statusCode: status));

      await expectLater(repository.delete(1), throwsA(matcher));
    });
  }
}
