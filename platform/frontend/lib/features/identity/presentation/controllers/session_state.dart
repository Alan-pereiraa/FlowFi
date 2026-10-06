import '../../domain/entities/user.dart';

/// App-wide session. The router derives every auth redirect from it.
sealed class SessionState {
  const SessionState();

  factory SessionState.fromUser(User user) => user.needsProfile
      ? SessionNeedsProfile(user)
      : SessionAuthenticated(user);

  User? get user => switch (this) {
    SessionNeedsProfile(:final user) ||
    SessionAuthenticated(:final user) => user,
    _ => null,
  };
}

/// Booting: restoring the stored session. [errorMessage] is set when the
/// restore failed for a reason other than a dead token (e.g. offline).
final class SessionUnknown extends SessionState {
  const SessionUnknown({this.errorMessage});

  final String? errorMessage;
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// Logged in, but `first_name` is still empty (first login).
final class SessionNeedsProfile extends SessionState {
  const SessionNeedsProfile(this.user);

  @override
  final User user;
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);

  @override
  final User user;
}
