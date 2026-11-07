import 'package:flutter/foundation.dart';

import 'goal.dart';

@immutable
class GoalCreation {
  const GoalCreation({
    required this.goal,
    this.initialCents = 0,
    this.initialDepositFailed = false,
  });

  final Goal goal;

  final int initialCents;

  final bool initialDepositFailed;
}
