import 'package:flutter/foundation.dart';

/// What the add/edit category form collects. Used for both create and update:
/// an update always sends every field, so `limitCents: null` clears the limit.
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

  /// Null removes (or never sets) the monthly limit.
  final int? limitCents;
}
