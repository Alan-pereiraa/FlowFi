import 'package:flutter/foundation.dart';

import '../../domain/entities/goal_creation.dart';

@immutable
class GoalFormState {
  const GoalFormState({
    this.saving = false,
    this.created,
    this.fieldErrors = const {},
    this.formError,
  });

  final bool saving;

  /// Set once the goal was created; the page then moves to the success screen.
  final GoalCreation? created;

  /// pt-BR messages keyed by backend field name.
  final Map<String, String> fieldErrors;
  final String? formError;
}
