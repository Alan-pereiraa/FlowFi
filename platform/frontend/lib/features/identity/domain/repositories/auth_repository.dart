import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<void> requestOtp(String email);

  Future<User> verifyOtp({required String email, required String code});

  Future<int?> storedUserId();

  Future<void> logout();

  Future<void> clearSession();
}
