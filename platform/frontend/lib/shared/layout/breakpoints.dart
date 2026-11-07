import 'dart:math' as math;

abstract final class Breakpoints {
  static const compact = 600.0;

  static const medium = 1024.0;

  static const contentMax = 1120.0;

  static const formMax = 480.0;

  static double pagePadding(double width) {
    if (width < compact) return 16;
    if (width < medium) return 24;
    return 32;
  }

  static int columnsFor(
    double width, {
    double minTileWidth = 320,
    double spacing = 16,
    int maxColumns = 3,
  }) {
    final fit = ((width + spacing) / (minTileWidth + spacing)).floor();
    return math.max(1, math.min(maxColumns, fit));
  }
}
