import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';
import 'category_type.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.type = CategoryType.expense,
    this.limitAmount,
    this.limitCents,
  });

  final int id;
  final String name;
  final String icon;
  final String color;
  final CategoryType type;

  final Money? limitAmount;

  final int? limitCents;

  bool get hasLimit => limitCents != null;

  bool get isIncome => type == CategoryType.income;

  int? usedPercent(int spentCents) {
    final limit = limitCents;
    if (limit == null || limit <= 0) return null;
    return (spentCents * 100) ~/ limit;
  }

  int? remainingCents(int usedCents) {
    final limit = limitCents;
    if (limit == null) return null;
    return usedCents >= limit ? 0 : limit - usedCents;
  }

  bool isNearLimit(int spentCents) =>
      !isIncome && (usedPercent(spentCents) ?? 0) >= 80;

  bool isAtLimit(int spentCents) =>
      !isIncome && limitCents != null && spentCents == limitCents;

  bool isOverLimit(int spentCents) {
    final limit = limitCents;
    return !isIncome && limit != null && limit > 0 && spentCents > limit;
  }

  bool reachedGoal(int receivedCents) {
    final limit = limitCents;
    return isIncome && limit != null && limit > 0 && receivedCents >= limit;
  }

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.type == type &&
      other.limitAmount == limitAmount &&
      other.limitCents == limitCents;

  @override
  int get hashCode =>
      Object.hash(id, name, icon, color, type, limitAmount, limitCents);
}
