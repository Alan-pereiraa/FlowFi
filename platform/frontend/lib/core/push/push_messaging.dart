import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => PushMessaging(FirebaseMessaging.instance),
);

/// The only FCM touchpoint. Uses the classic registration token, which is what
/// the backend's `CloudMessage::toToken()` expects; the newer `register()` API
/// yields a Firebase Installation ID instead.
class PushMessaging {
  PushMessaging(this._messaging);

  final FirebaseMessaging _messaging;

  /// False when the user blocked notifications.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus != AuthorizationStatus.denied;
  }

  // ignore: deprecated_member_use
  Future<String?> token() => _messaging.getToken();

  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
