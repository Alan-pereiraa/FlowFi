import 'package:material_ui/material_ui.dart';

/// `#RRGGBB` ↔ [Color] for the colors the API stores on categories and goals.
abstract final class HexColor {
  /// Choices offered by the color picker. These are user data sent to the
  /// API, not theme colors.
  static const palette = [
    '#00530C',
    '#43A94D',
    '#1E88E5',
    '#3949AB',
    '#8E24AA',
    '#D81B60',
    '#BA1A1A',
    '#F4511E',
    '#FB8C00',
    '#FDD835',
    '#00897B',
    '#6D4C41',
    '#546E7A',
    '#757575',
  ];

  static Color? tryParse(String? hex) {
    if (hex == null) return null;
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex);
    if (match == null) return null;
    return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
  }

  /// [hex] or [fallback] when it is missing or malformed.
  static Color parse(String? hex, {required Color fallback}) =>
      tryParse(hex) ?? fallback;
}
