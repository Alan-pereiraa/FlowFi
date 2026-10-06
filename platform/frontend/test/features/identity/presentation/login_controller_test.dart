import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/unauthorized_signal.dart';
import 'package:flowfi_app/features/identity/data/repositories/auth_repository_impl.dart';
import 'package:flowfi_app/features/identity/data/repositories/user_repository_impl.dart';
import 'package:flowfi_app/features/identity/domain/entities/user.dart';
import 'package:flowfi_app/features/identity/domain/repositories/auth_repository.dart';
import 'package:flowfi_app/features/identity/domain/repositories/user_repository.dart';
import 'package:flowfi_app/features/identity/presentation/controllers/login_controller.dart';
import 'package:flowfi_app/features/identity/presentation/controllers/session_controller.dart';
import 'package:flowfi_app/features/identity/presentation/controllers/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockUsers extends Mock implements UserRepository {}

void main() {
  late _MockAuth auth;
  late ProviderContainer container;

  setUp(() async {
    auth = _MockAuth();
    when(() => auth.storedUserId()).thenAnswer((_) async => null);
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(_MockUsers()),
        unauthorizedSignalProvider.overrideWithValue(UnauthorizedSignal()),
      ],
    );
    container.listen(sessionControllerProvider, (_, _) {});
    container.listen(loginControllerProvider, (_, _) {});
    await pumpEventQueue();
  });

  LoginController controller() =>
      container.read(loginControllerProvider.notifier);

  test('invalid email is rejected without calling the API', () async {
    await controller().sendCode('not-an-email');

    expect(container.read(loginControllerProvider).emailError, isNotNull);
    verifyNever(() => auth.requestOtp(any()));
  });

  test('sending a code normalizes the email and starts the cooldown', () async {
    when(() => auth.requestOtp(any())).thenAnswer((_) async {});

    await controller().sendCode('  Alex@Example.com ');

    verify(() => auth.requestOtp('alex@example.com')).called(1);
    final state = container.read(loginControllerProvider);
    expect(state.codeSent, isTrue);
    expect(state.cooldownSeconds, 60);
    expect(state.canSend, isFalse);
  });

  test('429 without Retry-After falls back to the 60 s cooldown', () async {
    when(() => auth.requestOtp(any())).thenThrow(const RateLimitedFailure());

    await controller().sendCode('a@b.com');

    final state = container.read(loginControllerProvider);
    expect(state.cooldownSeconds, 60);
    expect(state.formError, isNotNull);
  });

  test('successful verify signs the session in', () async {
    when(() => auth.verifyOtp(email: 'a@b.com', code: '123456'))
        .thenAnswer((_) async => const User(id: 1, email: 'a@b.com'));

    await controller().verify('a@b.com', '123456');

    expect(
      container.read(sessionControllerProvider),
      isA<SessionNeedsProfile>(),
    );
  });

  test('too many attempts clears the code and re-enables sending', () async {
    when(() => auth.requestOtp(any())).thenAnswer((_) async {});
    when(
      () => auth.verifyOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenThrow(
      const ValidationFailure(
        fieldErrors: {
          'code': ['Too many attempts. Request a new code.'],
        },
      ),
    );

    await controller().sendCode('a@b.com');
    await controller().verify('a@b.com', '000000');

    final state = container.read(loginControllerProvider);
    expect(state.codeError, 'Muitas tentativas. Solicite um novo código.');
    expect(state.codeResetCount, 1);
    expect(state.canSend, isTrue);
  });

  test('deactivated account shows the error under the email', () async {
    when(
      () => auth.verifyOtp(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    ).thenThrow(
      const ValidationFailure(
        fieldErrors: {
          'email': ['This account has been deactivated.'],
        },
      ),
    );

    await controller().verify('a@b.com', '123456');

    expect(
      container.read(loginControllerProvider).emailError,
      'Esta conta foi desativada.',
    );
  });
}
