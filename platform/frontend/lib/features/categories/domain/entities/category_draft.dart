import 'package:flutter/foundation.dart';

import 'category_type.dart';

@immutable
class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.icon,
    required this.color,
    this.type = CategoryType.expense,
    this.limitCents,
  });

  final String name;
  final String icon;
  final String color;
  final CategoryType type;

  final int? limitCents;
}
