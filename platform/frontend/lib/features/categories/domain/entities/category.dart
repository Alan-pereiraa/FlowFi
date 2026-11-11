import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.limitAmount,
    this.limitCents,
  });

  final int id;
  final String name;
  final String icon;
  final String color;

  final Money? limitAmount;

  final int? limitCents;

  bool get hasLimit => limitCents != null;

  int? usedPercent(int spentCents) {
    final limit = limitCents;
    if (limit == null || limit <= 0) return null;
    return (spentCents * 100) ~/ limit;
  }

  bool isNearLimit(int spentCents) => (usedPercent(spentCents) ?? 0) >= 80;

  bool isOverLimit(int spentCents) {
    final limit = limitCents;
    return limit != null && limit > 0 && spentCents > limit;
  }

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.limitAmount == limitAmount &&
      other.limitCents == limitCents;

  @override
  int get hashCode =>
      Object.hash(id, name, icon, color, limitAmount, limitCents);
}
