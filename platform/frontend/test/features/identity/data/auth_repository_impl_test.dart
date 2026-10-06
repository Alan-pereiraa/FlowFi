import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/api_exception.dart';
import 'package:flowfi_app/core/storage/secure_storage.dart';
import 'package:flowfi_app/features/identity/data/datasources/identity_api.dart';
import 'package:flowfi_app/features/identity/data/models/auth_response_dto.dart';
import 'package:flowfi_app/features/identity/data/models/user_dto.dart';
import 'package:flowfi_app/features/identity/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements IdentityApi {}

class _MockStorage extends Mock implements SecureStorage {}

void main() {
  late _MockApi api;
  late _MockStorage storage;
  late AuthRepositoryImpl repository;

  setUp(() {
    api = _MockApi();
    storage = _MockStorage();
    repository = AuthRepositoryImpl(api, storage);
    when(() => storage.clear()).thenAnswer((_) async {});
    when(
      () => storage.saveSession(
        token: any(named: 'token'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});
  });

  test('verifyOtp stores token and user id', () async {
    when(() => api.verifyOtp('a@b.com', '123456')).thenAnswer(
      (_) async => const AuthResponseDto(
        user: UserDto(id: 3, email: 'a@b.com'),
        token: '1|tok',
      ),
    );

    final user = await repository.verifyOtp(email: 'a@b.com', code: '123456');

    expect(user.id, 3);
    verify(() => storage.saveSession(token: '1|tok', userId: 3)).called(1);
  });

  test('verifyOtp rethrows a 422 as ValidationFailure and stores nothing', () {
    when(() => api.verifyOtp(any(), any())).thenThrow(
      const ApiException(
        statusCode: 422,
        fieldErrors: {
          'code': ['The code is invalid or has expired.'],
        },
      ),
    );

    expect(
      repository.verifyOtp(email: 'a@b.com', code: '000000'),
      throwsA(isA<ValidationFailure>()),
    );
    verifyNever(
      () => storage.saveSession(
        token: any(named: 'token'),
        userId: any(named: 'userId'),
      ),
    );
  });

  test('requestOtp rethrows a 429 as RateLimitedFailure', () {
    when(() => api.requestOtp(any()))
        .thenThrow(const ApiException(statusCode: 429));

    expect(
      repository.requestOtp('a@b.com'),
      throwsA(isA<RateLimitedFailure>()),
    );
  });

  test('logout clears the session even when the request fails', () async {
    when(() => api.logout()).thenThrow(const ApiException());

    await repository.logout();

    verify(() => storage.clear()).called(1);
  });

  test('storedUserId is null without a token', () async {
    when(() => storage.readToken()).thenAnswer((_) async => null);

    expect(await repository.storedUserId(), isNull);
  });
}
