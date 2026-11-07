import 'package:flutter/foundation.dart';

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

  final int initialCents;
}
