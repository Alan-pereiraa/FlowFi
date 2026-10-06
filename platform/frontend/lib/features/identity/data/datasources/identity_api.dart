import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/auth_response_dto.dart';
import '../models/profile_update_dto.dart';
import '../models/user_dto.dart';

final identityApiProvider = Provider<IdentityApi>(
  (ref) => IdentityApi(ref.watch(apiClientProvider)),
);

/// One method per Identity endpoint. Throws [ApiException].
class IdentityApi {
  IdentityApi(this._dio);

  final Dio _dio;

  Future<void> requestOtp(String email) =>
      _send(() => _dio.post<void>('/auth/otp/request', data: {'email': email}));

  Future<AuthResponseDto> verifyOtp(String email, String code) async {
    final response = await _send(
      () => _dio.post<Map<String, dynamic>>(
        '/auth/otp/verify',
        data: {'email': email, 'code': code},
      ),
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  Future<void> logout() => _send(() => _dio.post<void>('/auth/logout'));

  Future<UserDto> showUser(int id) async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>('/users/$id'),
    );
    return _unwrapUser(response.data!);
  }

  Future<UserDto> updateUser(int id, ProfileUpdateDto body) async {
    final response = await _send(
      () => _dio.patch<Map<String, dynamic>>('/users/$id', data: body.toJson()),
    );
    return _unwrapUser(response.data!);
  }

  Future<void> deleteUser(int id) =>
      _send(() => _dio.delete<void>('/users/$id'));

  /// `GET`/`PATCH /users/{id}` wrap the resource in `{ "data": {...} }`.
  UserDto _unwrapUser(Map<String, dynamic> body) =>
      UserDto.fromJson(body['data'] as Map<String, dynamic>);

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
