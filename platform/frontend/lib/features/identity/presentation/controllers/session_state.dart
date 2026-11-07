import '../../domain/entities/user.dart';

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

final class SessionUnknown extends SessionState {
  const SessionUnknown({this.errorMessage});

  final String? errorMessage;
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

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
