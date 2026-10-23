import 'package:flutter/foundation.dart';

@immutable
class DashboardTag {
  const DashboardTag({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final int id;
  final String name;
  final String icon;
  final String color;

  @override
  bool operator ==(Object other) =>
      other is DashboardTag &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color;

  @override
  int get hashCode => Object.hash(id, name, icon, color);
}
