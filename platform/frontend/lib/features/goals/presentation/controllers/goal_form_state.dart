import 'package:flutter/foundation.dart';

import '../../domain/entities/goal.dart';

@immutable
class GoalFormState {
  const GoalFormState({
    this.saving = false,
    this.created,
    this.fieldErrors = const {},
    this.formError,
  });

  final bool saving;

  final Goal? created;

  final Map<String, String> fieldErrors;
  final String? formError;
}
