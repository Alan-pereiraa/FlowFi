import 'package:material_ui/material_ui.dart';

/// Colors a user can give a category or goal. They are *data* (stored as
/// `#RRGGBB` by the API), not theme tokens, so hex literals live here and
/// nowhere in widgets. The set mirrors the backend seeders.
abstract final class AppPalette {
  /// Used when the user saves without choosing: the brand green.
  static const defaultHex = '#00530C';

  static const hexes = <String>[
    '#00530C',
    '#2E7D32',
    '#66BB6A',
    '#00897B',
    '#26C6DA',
    '#42A5F5',
    '#5C6BC0',
    '#7E57C2',
    '#AB47BC',
    '#EC407A',
    '#EF5350',
    '#FF7043',
    '#FFCA28',
    '#8D6E63',
    '#78909C',
    '#37474F',
  ];

  /// Hues of the "choose a color" dot shown before anything is picked.
  static const wheel = <Color>[
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.red,
  ];

  /// `#RRGGBB` -> [Color]. Falls back to [fallback], then to the brand green.
  static Color parse(String? hex, {Color? fallback}) {
    final cleaned = (hex ?? '').replaceFirst('#', '');
    final value = cleaned.length == 6 ? int.tryParse(cleaned, radix: 16) : null;
    if (value == null) {
      return fallback ?? parse(defaultHex);
    }
    return Color(0xFF000000 | value);
  }
}
