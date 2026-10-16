import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';

/// Body of `POST /categories`.
@immutable
class CategoryInput {
  const CategoryInput({
    required this.name,
    required this.icon,
    required this.color,
    this.limitAmount,
  });

  final String name;
  final String icon;
  final String color;

  /// Null = no limit.
  final Money? limitAmount;
}
