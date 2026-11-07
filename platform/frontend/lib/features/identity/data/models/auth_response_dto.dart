import 'user_dto.dart';

class AuthResponseDto {
  const AuthResponseDto({required this.user, required this.token});

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      AuthResponseDto(
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
      );

  final UserDto user;
  final String token;
}
