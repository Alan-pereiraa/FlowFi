import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/identity_api.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(identityApiProvider),
    ref.watch(secureStorageProvider),
  ),
);

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._storage);

  final IdentityApi _api;
  final SecureStorage _storage;

  @override
  Future<void> requestOtp(String email) =>
      guardApi(() => _api.requestOtp(email));

  @override
  Future<User> verifyOtp({required String email, required String code}) async {
    final response = await guardApi(() => _api.verifyOtp(email, code));
    await _storage.saveSession(token: response.token, userId: response.user.id);
    return response.user.toEntity();
  }

  @override
  Future<int?> storedUserId() async {
    final token = await _storage.readToken();
    if (token == null) return null;
    return _storage.readUserId();
  }

  @override
  Future<void> logout() async {
    try {
      await guardApi(_api.logout);
    } on Failure {
      // Offline or token already dead: the local session ends regardless.
    } finally {
      await _storage.clear();
    }
  }

  @override
  Future<void> clearSession() => _storage.clear();
}
