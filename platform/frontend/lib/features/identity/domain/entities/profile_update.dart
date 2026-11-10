import 'package:flutter/foundation.dart';

@immutable
class ProfileUpdate {
  const ProfileUpdate({
    required this.firstName,
    this.lastName,
    this.phoneNumber,
  });

  final String firstName;
  final String? lastName;
  final String? phoneNumber;
}
