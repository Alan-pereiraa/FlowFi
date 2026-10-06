import 'package:flutter/foundation.dart';

/// Fields sent on `PATCH /users/{id}`. Null [email] means "don't change it";
/// the other fields are always sent, and null clears them.
@immutable
class ProfileUpdate {
  const ProfileUpdate({
    required this.firstName,
    this.lastName,
    this.phoneNumber,
    this.email,
  });

  final String firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? email;
}
