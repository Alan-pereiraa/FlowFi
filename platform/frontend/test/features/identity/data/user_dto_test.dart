import 'package:flowfi_app/features/identity/data/models/auth_response_dto.dart';
import 'package:flowfi_app/features/identity/data/models/user_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Sample shaped like the backend UserResource right after a first login.
  const freshUser = {
    'id': 7,
    'first_name': null,
    'last_name': null,
    'email': 'alex@example.com',
    'phone_number': null,
    'created_at': '2026-10-03T12:00:00.000000Z',
    'updated_at': '2026-10-03T12:00:00.000000Z',
  };

  test('parses a user with nullable profile fields', () {
    final user = UserDto.fromJson(freshUser).toEntity();

    expect(user.id, 7);
    expect(user.email, 'alex@example.com');
    expect(user.firstName, isNull);
    expect(user.needsProfile, isTrue);
    expect(user.createdAt, DateTime.utc(2026, 10, 3, 12));
  });

  test('a user with a first name no longer needs a profile', () {
    final user = UserDto.fromJson({
      ...freshUser,
      'first_name': 'Alex',
      'last_name': 'Junior',
    }).toEntity();

    expect(user.needsProfile, isFalse);
    expect(user.displayName, 'Alex Junior');
    expect(user.initials, 'AJ');
  });

  test('verify response has user and token without a data envelope', () {
    final dto = AuthResponseDto.fromJson({'user': freshUser, 'token': '1|abc'});

    expect(dto.token, '1|abc');
    expect(dto.user.id, 7);
  });
}
