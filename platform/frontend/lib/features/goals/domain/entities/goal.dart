import 'package:flutter/foundation.dart';

@immutable
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.targetCents,
    required this.currentCents,
    this.expiresAt,
  });

  final int id;
  final String name;

  final String icon;

  final String color;
  final int targetCents;

  final int currentCents;

  final DateTime? expiresAt;

  bool get isOpenEnded => expiresAt == null;

  bool get reached => targetCents > 0 && currentCents >= targetCents;

  double get progress {
    if (targetCents <= 0 || currentCents <= 0) return 0;
    return (currentCents / targetCents).clamp(0.0, 1.0).toDouble();
  }

  int get percent {
    if (targetCents <= 0 || currentCents <= 0) return 0;
    final value = (currentCents * 100) ~/ targetCents;
    return value > 100 ? 100 : value;
  }

  int? monthlyContributionCents(DateTime now) {
    final end = expiresAt;
    if (end == null || reached) return null;

    final days = DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    final months = days <= 0 ? 1 : (days / 30.4375).ceil();

    final remaining = targetCents - currentCents;
    return (remaining + months - 1) ~/ months;
  }

  Goal copyWith({int? currentCents}) => Goal(
    id: id,
    name: name,
    icon: icon,
    color: color,
    targetCents: targetCents,
    currentCents: currentCents ?? this.currentCents,
    expiresAt: expiresAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Goal &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.targetCents == targetCents &&
      other.currentCents == currentCents &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      Object.hash(id, name, icon, color, targetCents, currentCents, expiresAt);
}
