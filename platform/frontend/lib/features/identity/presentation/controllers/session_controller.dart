import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/unauthorized_signal.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user.dart';
import 'session_state.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final subscription = ref
        .watch(unauthorizedSignalProvider)
        .stream
        .listen((_) => state = const SessionUnauthenticated());
    ref.onDispose(subscription.cancel);

    Future.microtask(restore);
    return const SessionUnknown();
  }

  /// Reads the stored session and loads the user. Also used as "retry" on the
  /// splash screen.
  Future<void> restore() async {
    state = const SessionUnknown();
    final auth = ref.read(authRepositoryProvider);

    final userId = await auth.storedUserId();
    if (!ref.mounted) return;
    if (userId == null) {
      state = const SessionUnauthenticated();
      return;
    }

    try {
      final user = await ref.read(userRepositoryProvider).show(userId);
      if (!ref.mounted) return;
      state = SessionState.fromUser(user);
    } on UnauthorizedFailure {
      if (ref.mounted) state = const SessionUnauthenticated();
    } on NotFoundFailure {
      // Stored id doesn't match the token: treat the session as broken.
      await auth.clearSession();
      if (ref.mounted) state = const SessionUnauthenticated();
    } on Failure catch (failure) {
      if (ref.mounted) {
        state = SessionUnknown(errorMessage: ErrorMessages.general(failure));
      }
    }
  }

  void signedIn(User user) => state = SessionState.fromUser(user);

  void userUpdated(User user) => state = SessionState.fromUser(user);

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (ref.mounted) state = const SessionUnauthenticated();
  }

  /// Soft-deletes the account. Throws `Failure`; the email stays blocked for
  /// future logins.
  Future<void> deleteAccount() async {
    final user = state.user;
    if (user == null) return;
    await ref.read(userRepositoryProvider).destroy(user.id);
    await ref.read(authRepositoryProvider).clearSession();
    if (ref.mounted) state = const SessionUnauthenticated();
  }
}
