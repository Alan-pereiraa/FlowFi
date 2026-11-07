import '../entities/profile_update.dart';
import '../entities/user.dart';

abstract interface class UserRepository {
  Future<User> show(int id);

  Future<User> update(int id, ProfileUpdate data);

  Future<void> destroy(int id);
}
