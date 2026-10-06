import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/identity_api.dart';
import '../models/profile_update_dto.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(ref.watch(identityApiProvider)),
);

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._api);

  final IdentityApi _api;

  @override
  Future<User> show(int id) async {
    final dto = await guardApi(() => _api.showUser(id));
    return dto.toEntity();
  }

  @override
  Future<User> update(int id, ProfileUpdate data) async {
    final dto = await guardApi(
      () => _api.updateUser(id, ProfileUpdateDto(data)),
    );
    return dto.toEntity();
  }

  @override
  Future<void> destroy(int id) => guardApi(() => _api.deleteUser(id));
}
