import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/profile_update.dart';
import 'profile_form_state.dart';
import 'session_controller.dart';

final profileFormControllerProvider =
    NotifierProvider.autoDispose<ProfileFormController, ProfileFormState>(
      ProfileFormController.new,
    );

/// Complete-profile (first login) and edit-profile forms, plus logout and
/// account deletion, which have no screen of their own in the design.
class ProfileFormController extends Notifier<ProfileFormState> {
  static const _fields = ['first_name', 'last_name', 'phone_number', 'email'];

  @override
  ProfileFormState build() => const ProfileFormState();

  Future<void> save(ProfileUpdate data) async {
    final user = ref.read(sessionControllerProvider).user;
    if (user == null || state.busy) return;

    state = const ProfileFormState(saving: true);
    try {
      final updated = await ref
          .read(userRepositoryProvider)
          .update(user.id, data);
      if (!ref.mounted) return;
      state = const ProfileFormState(saved: true);
      ref.read(sessionControllerProvider.notifier).userUpdated(updated);
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return;
      final fieldErrors = {
        for (final field in _fields)
          field: ?ErrorMessages.forField(failure, field),
      };
      state = ProfileFormState(
        fieldErrors: fieldErrors,
        formError: fieldErrors.isEmpty ? ErrorMessages.general(failure) : null,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = ProfileFormState(formError: ErrorMessages.general(failure));
    }
  }

  Future<void> logout() async {
    if (state.busy) return;
    state = const ProfileFormState(leaving: true);
    await ref.read(sessionControllerProvider.notifier).logout();
  }

  Future<void> deleteAccount() async {
    if (state.busy) return;
    state = const ProfileFormState(leaving: true);
    try {
      await ref.read(sessionControllerProvider.notifier).deleteAccount();
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = ProfileFormState(formError: ErrorMessages.general(failure));
    }
  }
}
