import 'package:flowfi_app/app/router.dart';
import 'package:flowfi_app/app/routes.dart';
import 'package:flowfi_app/features/identity/domain/entities/user.dart';
import 'package:flowfi_app/features/identity/presentation/controllers/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const named = User(id: 1, email: 'a@b.com', firstName: 'Alex');
  const unnamed = User(id: 1, email: 'a@b.com');

  test('unknown session always shows the splash', () {
    expect(
      redirectFor(const SessionUnknown(), Routes.dashboard),
      Routes.splash,
    );
    expect(redirectFor(const SessionUnknown(), Routes.splash), isNull);
  });

  test('unauthenticated goes to login', () {
    const s = SessionUnauthenticated();
    expect(redirectFor(s, Routes.dashboard), Routes.login);
    expect(redirectFor(s, Routes.editProfile), Routes.login);
    expect(redirectFor(s, Routes.login), isNull);
  });

  test('needs profile is locked on the complete-profile form', () {
    const s = SessionNeedsProfile(unnamed);
    expect(redirectFor(s, Routes.dashboard), Routes.completeProfile);
    expect(redirectFor(s, Routes.completeProfile), isNull);
  });

  test('authenticated leaves auth routes', () {
    const s = SessionAuthenticated(named);
    expect(redirectFor(s, Routes.login), Routes.dashboard);
    expect(redirectFor(s, Routes.splash), Routes.dashboard);
    expect(redirectFor(s, Routes.completeProfile), Routes.profileSuccess);
    expect(redirectFor(s, Routes.goals), isNull);
    expect(redirectFor(s, Routes.editProfile), isNull);
  });

  test('session state is derived from the user', () {
    expect(SessionState.fromUser(unnamed), isA<SessionNeedsProfile>());
    expect(SessionState.fromUser(named), isA<SessionAuthenticated>());
  });
}
