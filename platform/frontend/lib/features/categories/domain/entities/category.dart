import 'package:flutter/foundation.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.limitCents,
  });

  final int id;
  final String name;

  /// Icon name from the shared catalog (`AppIcons`).
  final String icon;

  /// `#RRGGBB`.
  final String color;

  /// Monthly spending cap in cents; null means no limit.
  final int? limitCents;

  bool get hasLimit => limitCents != null;

  /// Whole percent of the limit already [spentCents], rounded down; null when
  /// there is no limit. Can exceed 100.
  int? usedPercent(int spentCents) {
    final limit = limitCents;
    if (limit == null || limit <= 0) return null;
    return (spentCents * 100) ~/ limit;
  }

  /// At or past 80% of the limit: the same threshold the backend uses for its
  /// "Category limit warning" notification.
  bool isNearLimit(int spentCents) => (usedPercent(spentCents) ?? 0) >= 80;

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.limitCents == limitCents;

  @override
  int get hashCode => Object.hash(id, name, icon, color, limitCents);
}
