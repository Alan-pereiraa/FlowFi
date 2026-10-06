import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final unauthorizedSignalProvider = Provider<UnauthorizedSignal>((ref) {
  final signal = UnauthorizedSignal();
  ref.onDispose(signal.dispose);
  return signal;
});

/// Fired by `AuthInterceptor` on a 401. `SessionController` listens to it.
/// Exists so the interceptor never depends on the session controller, which
/// would create a provider cycle.
class UnauthorizedSignal {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void fire() => _controller.add(null);

  void dispose() => _controller.close();
}
