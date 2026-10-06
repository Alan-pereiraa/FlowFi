import 'package:flutter/foundation.dart';

@immutable
class ProfileFormState {
  const ProfileFormState({
    this.saving = false,
    this.leaving = false,
    this.saved = false,
    this.fieldErrors = const {},
    this.formError,
  });

  final bool saving;

  /// Logging out or deleting the account.
  final bool leaving;

  /// The last save succeeded.
  final bool saved;

  /// pt-BR messages keyed by backend field name.
  final Map<String, String> fieldErrors;
  final String? formError;

  bool get busy => saving || leaving;
}
