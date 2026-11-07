import 'package:flutter/foundation.dart';

@immutable
class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.icon,
    required this.color,
    this.limitCents,
  });

  final String name;
  final String icon;
  final String color;

  final int? limitCents;
}
