import 'package:flutter/foundation.dart' show immutable;

import '../../domain/entities/goal.dart';

/// How the goal screen ended; the page shows a message and leaves.
enum GoalOutcome { updated, removed }

@immutable
class GoalDetailState {
  const GoalDetailState({
    this.loadingInitial = false,
    this.goal,
    this.loadError,
    this.saving = false,
    this.depositing = false,
    this.removing = false,
    this.outcome,
    this.depositCount = 0,
    this.fieldErrors = const {},
    this.depositError,
    this.formError,
  });

  /// Opened by id alone (deep link, browser refresh): the goal is fetched.
  final bool loadingInitial;

  /// The latest known goal: fetched, saved, or after a deposit.
  final Goal? goal;
  final String? loadError;

  final bool saving;
  final bool depositing;
  final bool removing;
  final GoalOutcome? outcome;

  /// Bumped on every successful deposit, so the page can react to each one
  /// (clear the field, say "Valor adicionado.") even when the goal looks the
  /// same.
  final int depositCount;

  /// pt-BR messages keyed by backend field name (the edit form).
  final Map<String, String> fieldErrors;
  final String? depositError;
  final String? formError;

  bool get busy => saving || depositing || removing;

  GoalDetailState copyWith({
    bool? loadingInitial,
    Goal? goal,
    String? Function()? loadError,
    bool? saving,
    bool? depositing,
    bool? removing,
    GoalOutcome? Function()? outcome,
    int? depositCount,
    Map<String, String>? fieldErrors,
    String? Function()? depositError,
    String? Function()? formError,
  }) {
    return GoalDetailState(
      loadingInitial: loadingInitial ?? this.loadingInitial,
      goal: goal ?? this.goal,
      loadError: loadError == null ? this.loadError : loadError(),
      saving: saving ?? this.saving,
      depositing: depositing ?? this.depositing,
      removing: removing ?? this.removing,
      outcome: outcome == null ? this.outcome : outcome(),
      depositCount: depositCount ?? this.depositCount,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      depositError: depositError == null ? this.depositError : depositError(),
      formError: formError == null ? this.formError : formError(),
    );
  }
}
