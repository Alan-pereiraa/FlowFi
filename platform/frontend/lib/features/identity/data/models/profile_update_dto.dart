import '../../domain/entities/profile_update.dart';

class ProfileUpdateDto {
  const ProfileUpdateDto(this.data);

  final ProfileUpdate data;

  Map<String, dynamic> toJson() => {
    'first_name': data.firstName,
    'last_name': data.lastName,
    'phone_number': data.phoneNumber,
  };
}
