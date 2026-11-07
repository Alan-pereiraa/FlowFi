import 'package:flutter/foundation.dart';

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
