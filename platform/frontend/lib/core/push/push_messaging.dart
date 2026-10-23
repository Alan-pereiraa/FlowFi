import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => PushMessaging(FirebaseMessaging.instance),
);

class PushMessaging {
  PushMessaging(this._messaging);

  final FirebaseMessaging _messaging;

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus != AuthorizationStatus.denied;
  }

  // ignore: deprecated_member_use
  Future<String?> token() => _messaging.getToken();

  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
