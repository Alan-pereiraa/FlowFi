import 'package:flutter/foundation.dart';

/// What the create-goal form collects.
// GAP: the API has no "initial amount" on a goal. It is sent as a first
// transfer into the goal right after the goal is created (see
// `GoalRepositoryImpl.create`).
@immutable
class NewGoal {
  const NewGoal({
    required this.name,
    required this.icon,
    required this.color,
    required this.targetCents,
    this.expiresAt,
    this.initialCents = 0,
  });

  final String name;
  final String icon;
  final String color;
  final int targetCents;
  final DateTime? expiresAt;

  /// Amount already saved; 0 when the field was left empty.
  final int initialCents;
}
