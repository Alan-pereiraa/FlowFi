import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/push/push_messaging.dart';
import '../data/repositories/device_repository_impl.dart';
import '../domain/repositories/device_repository.dart';

final pushRegistrationProvider = Provider<PushRegistration>((ref) {
  final registration = PushRegistration(
    ref.watch(pushMessagingProvider),
    ref.watch(deviceRepositoryProvider),
  );
  ref.onDispose(registration.dispose);
  return registration;
});

class PushRegistration {
  PushRegistration(this._push, this._devices);

  final PushMessaging _push;
  final DeviceRepository _devices;
  StreamSubscription<String>? _refresh;

  Future<void> start() async {
    try {
      if (!await _push.requestPermission()) return;
      final token = await _push.token();
      if (token != null) await _register(token);
      _refresh ??= _push.onTokenRefresh.listen(_register);
    } on Exception catch (e) {
      debugPrint('[FCM] start failed: $e');
    }
  }

  Future<void> stop() async {
    await dispose();
    try {
      final token = await _push.token();
      if (token != null) await _devices.unregister(token);
    } on Exception catch (e) {
      debugPrint('[FCM] stop failed: $e');
    }
  }

  Future<void> dispose() async {
    await _refresh?.cancel();
    _refresh = null;
  }

  Future<void> _register(String token) async {
    try {
      await _devices.register(token);
    } on Failure catch (e) {
      debugPrint('[FCM] register failed: $e');
    }
  }
}
