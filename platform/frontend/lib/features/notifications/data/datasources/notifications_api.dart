import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated.dart';
import '../models/notification_dto.dart';

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(apiClientProvider)),
);

class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

  Future<Paginated<NotificationDto>> list({
    String? status,
    required int page,
    required int perPage,
  }) async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'status': ?status, 'page': page, 'per_page': perPage},
      ),
    );
    return Paginated.fromJson(response.data!, NotificationDto.fromJson);
  }

  Future<NotificationDto> markAsRead(int id) async {
    final response = await _send(
      () => _dio.patch<Map<String, dynamic>>('/notifications/$id/read'),
    );
    return NotificationDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(int id) =>
      _send(() => _dio.delete<void>('/notifications/$id'));

  Future<void> registerDevice(String token, String platform) => _send(
    () => _dio.post<void>(
      '/notifications/devices',
      data: {'token': token, 'platform': platform},
    ),
  );

  Future<void> unregisterDevice(String token) => _send(
    () => _dio.delete<void>('/notifications/devices', data: {'token': token}),
  );

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
