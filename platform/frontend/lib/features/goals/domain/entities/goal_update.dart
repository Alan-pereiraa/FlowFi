import 'package:flutter/foundation.dart';

/// What the edit-goal form collects. An update always sends every field, so
/// `expiresAt: null` turns the goal into an open-ended one.
@immutable
class GoalUpdate {
  const GoalUpdate({
    required this.name,
    required this.icon,
    required this.color,
    required this.targetCents,
    this.expiresAt,
  });

  final String name;
  final String icon;
  final String color;
  final int targetCents;

  /// Null removes the deadline.
  final DateTime? expiresAt;
}
