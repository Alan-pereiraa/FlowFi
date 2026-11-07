import 'package:flutter/foundation.dart';

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

  final DateTime? expiresAt;
}
