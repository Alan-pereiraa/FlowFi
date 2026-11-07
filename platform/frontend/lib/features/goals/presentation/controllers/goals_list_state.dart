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

  final bool loading;

  final bool loaded;
  final List<Goal> goals;

  final String? errorMessage;

  bool get showSpinner => loading && !loaded;

  bool get showError => !loaded && !loading && errorMessage != null;
}
