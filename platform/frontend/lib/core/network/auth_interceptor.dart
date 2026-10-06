import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';
import 'unauthorized_signal.dart';

/// Adds the bearer token and ends the session on a 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._unauthorized);

  final SecureStorage _storage;
  final UnauthorizedSignal _unauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && hadToken) {
      await _storage.clear();
      _unauthorized.fire();
    }
    handler.next(err);
  }
}
