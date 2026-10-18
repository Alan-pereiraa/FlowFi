import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(apiClientProvider)),
);

class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

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
