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

  /// Icon name from the shared catalog (`AppIcons`).
  final String icon;

  /// `#RRGGBB`.
  final String color;
  final int targetCents;

  /// Balance accumulated through transfers into the goal.
  final int currentCents;

  /// Null for an open-ended ("Contínuo") goal.
  final DateTime? expiresAt;

  bool get isOpenEnded => expiresAt == null;

  bool get reached => targetCents > 0 && currentCents >= targetCents;

  /// 0..1, for the progress bar.
  double get progress {
    if (targetCents <= 0 || currentCents <= 0) return 0;
    return (currentCents / targetCents).clamp(0.0, 1.0).toDouble();
  }

  /// Whole percent, rounded down so a goal never reads 100% before it is
  /// reached. Integer math: no float drift (0.29 * 100 != 29).
  int get percent {
    if (targetCents <= 0 || currentCents <= 0) return 0;
    final value = (currentCents * 100) ~/ targetCents;
    return value > 100 ? 100 : value;
  }

  /// Cents to set aside per month to reach the goal by [expiresAt], rounded
  /// up. Null for an open-ended or already reached goal. A deadline that is
  /// today or past counts as a single month.
  int? monthlyContributionCents(DateTime now) {
    final end = expiresAt;
    if (end == null || reached) return null;

    // UTC midnights: a daylight-saving shift can't turn a day into 23 hours.
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
