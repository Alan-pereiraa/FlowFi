import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/notifications_api.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepositoryImpl(ref.watch(notificationsApiProvider)),
);

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl(this._api);

  final NotificationsApi _api;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  Future<void> register(String token) =>
      guardApi(() => _api.registerDevice(token, _platform));

  @override
  Future<void> unregister(String token) =>
      guardApi(() => _api.unregisterDevice(token));
}
