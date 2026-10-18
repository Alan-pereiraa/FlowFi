import 'package:flutter/foundation.dart';

import '../../domain/entities/goal.dart';

@immutable
class GoalsListState {
  const GoalsListState({
    this.loading = false,
    this.loaded = false,
    this.goals = const <Goal>[],
    this.errorMessage,
  });

  /// A request is in flight (first load or a refresh).
  final bool loading;

  /// At least one load has succeeded, so [goals] is real data (maybe empty).
  final bool loaded;
  final List<Goal> goals;

  /// pt-BR message of the last failed load; null after a success.
  final String? errorMessage;

  /// Full-screen spinner: nothing to show yet.
  bool get showSpinner => loading && !loaded;

  /// Full-screen error: nothing to show and the load failed.
  bool get showError => !loaded && !loading && errorMessage != null;
}
