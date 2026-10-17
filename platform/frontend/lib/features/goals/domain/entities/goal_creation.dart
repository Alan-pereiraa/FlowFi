import 'package:flutter/foundation.dart';

import 'goal.dart';

/// Result of creating a goal. Creating the goal and depositing its initial
/// amount are two API calls; the second can fail on its own.
@immutable
class GoalCreation {
  const GoalCreation({
    required this.goal,
    this.initialCents = 0,
    this.initialDepositFailed = false,
  });

  /// The goal as stored, with `currentCents` already including the deposit
  /// when it went through.
  final Goal goal;

  /// The initial amount the user asked for.
  final int initialCents;

  /// The goal exists but its initial amount was not registered.
  final bool initialDepositFailed;
}
