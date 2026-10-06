import '../../domain/entities/user.dart';

/// Mirrors the backend `UserResource` (the inner object, without envelope).
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as int,
    email: json['email'] as String,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    phoneNumber: json['phone_number'] as String?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? createdAt;
  final String? updatedAt;

  User toEntity() => User(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    createdAt: createdAt == null ? null : DateTime.tryParse(createdAt!),
    updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt!),
  );
}
