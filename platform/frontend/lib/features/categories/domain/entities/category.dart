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
  });

  final int id;
  final String name;

  /// Material icon name from the backend catalog.
  final String icon;

  /// `#RRGGBB`.
  final String color;

  /// Monthly cap; null means "Sem limite".
  final Money? limitAmount;

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.limitAmount == limitAmount;

  @override
  int get hashCode => Object.hash(id, name, icon, color, limitAmount);
}
