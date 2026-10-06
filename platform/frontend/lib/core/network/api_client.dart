import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/env.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'unauthorized_signal.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${Env.apiBaseUrl}/api/v1',
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      ref.watch(secureStorageProvider),
      ref.watch(unauthorizedSignalProvider),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
