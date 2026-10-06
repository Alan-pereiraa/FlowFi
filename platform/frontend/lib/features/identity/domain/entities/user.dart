import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// First login: the account exists but has no name yet.
  bool get needsProfile => firstName == null || firstName!.trim().isEmpty;

  String get displayName => [
    firstName,
    lastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  String get initials {
    final name = displayName;
    if (name.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.email == email &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.phoneNumber == phoneNumber &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    firstName,
    lastName,
    phoneNumber,
    createdAt,
    updatedAt,
  );
}
