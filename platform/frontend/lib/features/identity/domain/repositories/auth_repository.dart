import '../entities/user.dart';

/// Passwordless auth and the locally stored session. Throws `Failure`.
abstract interface class AuthRepository {
  /// Mails a one-time code to [email].
  Future<void> requestOtp(String email);

  /// Exchanges the code for a token and stores the session (token + user id).
  Future<User> verifyOtp({required String email, required String code});

  /// Id of the stored session's user, or null when there is no session.
  Future<int?> storedUserId();

  /// Revokes the token on the server and always clears the local session,
  /// even if the request fails.
  Future<void> logout();

  /// Clears the local session without calling the API.
  Future<void> clearSession();
}
