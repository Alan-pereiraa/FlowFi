import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/unauthorized_signal.dart';
import 'package:flowfi_app/features/identity/data/repositories/auth_repository_impl.dart';
import 'package:flowfi_app/features/identity/data/repositories/user_repository_impl.dart';
import 'package:flowfi_app/features/identity/domain/entities/user.dart';
import 'package:flowfi_app/features/identity/domain/repositories/auth_repository.dart';
import 'package:flowfi_app/features/identity/domain/repositories/user_repository.dart';
import 'package:flowfi_app/features/identity/presentation/controllers/session_controller.dart';
import 'package:flowfi_app/features/identity/presentation/controllers/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockUsers extends Mock implements UserRepository {}

void main() {
  late _MockAuth auth;
  late _MockUsers users;
  late UnauthorizedSignal signal;

  setUp(() {
    auth = _MockAuth();
    users = _MockUsers();
    signal = UnauthorizedSignal();
    when(() => auth.clearSession()).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() => ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      userRepositoryProvider.overrideWithValue(users),
      unauthorizedSignalProvider.overrideWithValue(signal),
    ],
  );

  /// Reads the controller and lets the boot restore run.
  Future<SessionState> boot(ProviderContainer container) async {
    container.listen(sessionControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(sessionControllerProvider);
  }

  test('no stored session → unauthenticated', () async {
    when(() => auth.storedUserId()).thenAnswer((_) async => null);

    expect(await boot(makeContainer()), isA<SessionUnauthenticated>());
  });

  test('stored session with a named user → authenticated', () async {
    when(() => auth.storedUserId()).thenAnswer((_) async => 5);
    when(() => users.show(5)).thenAnswer(
      (_) async => const User(id: 5, email: 'a@b.com', firstName: 'A'),
    );

    expect(await boot(makeContainer()), isA<SessionAuthenticated>());
  });

  test('stored session with no name → needs profile', () async {
    when(() => auth.storedUserId()).thenAnswer((_) async => 5);
    when(() => users.show(5))
        .thenAnswer((_) async => const User(id: 5, email: 'a@b.com'));

    expect(await boot(makeContainer()), isA<SessionNeedsProfile>());
  });

  test('dead token on boot → unauthenticated', () async {
    when(() => auth.storedUserId()).thenAnswer((_) async => 5);
    when(() => users.show(5)).thenThrow(const UnauthorizedFailure());

    expect(await boot(makeContainer()), isA<SessionUnauthenticated>());
  });

  test('offline on boot → stays on splash with a retry message', () async {
    when(() => auth.storedUserId()).thenAnswer((_) async => 5);
    when(() => users.show(5)).thenThrow(const NetworkFailure());

    final state = await boot(makeContainer());
    expect(state, isA<SessionUnknown>());
    expect((state as SessionUnknown).errorMessage, isNotNull);
  });

  test('a 401 signal ends the session', () async {
    when(() => auth.storedUserId()).thenAnswer((_) async => 5);
    when(() => users.show(5)).thenAnswer(
      (_) async => const User(id: 5, email: 'a@b.com', firstName: 'A'),
    );
    final container = makeContainer();
    await boot(container);

    signal.fire();
    await pumpEventQueue();

    expect(
      container.read(sessionControllerProvider),
      isA<SessionUnauthenticated>(),
    );
  });
}
