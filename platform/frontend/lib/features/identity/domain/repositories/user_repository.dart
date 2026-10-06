import '../entities/profile_update.dart';
import '../entities/user.dart';

/// Self-service profile on `/users/{id}`; only the caller's own id works.
/// Throws `Failure`.
abstract interface class UserRepository {
  Future<User> show(int id);

  Future<User> update(int id, ProfileUpdate data);

  Future<void> destroy(int id);
}
