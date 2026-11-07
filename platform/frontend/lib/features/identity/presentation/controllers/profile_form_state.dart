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

  final bool leaving;

  final bool saved;

  final Map<String, String> fieldErrors;
  final String? formError;

  bool get busy => saving || leaving;
}
