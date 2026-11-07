import 'package:material_ui/material_ui.dart';

abstract final class AppPalette {
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

  static Color parse(String? hex, {Color? fallback}) {
    final cleaned = (hex ?? '').replaceFirst('#', '');
    final value = cleaned.length == 6 ? int.tryParse(cleaned, radix: 16) : null;
    if (value == null) {
      return fallback ?? parse(defaultHex);
    }
    return Color(0xFF000000 | value);
  }
}
