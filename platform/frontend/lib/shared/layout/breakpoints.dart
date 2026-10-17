import 'dart:math' as math;

/// Width classes shared by every screen, so mobile and web agree on when the
/// layout changes.
abstract final class Breakpoints {
  /// Phones. Single column.
  static const compact = 600.0;

  /// Tablets and small windows.
  static const medium = 1024.0;

  /// Widest a page's content grows; beyond it the page is centered.
  static const contentMax = 1120.0;

  /// Widest a form grows.
  static const formMax = 480.0;

  /// Horizontal page padding for a viewport [width].
  static double pagePadding(double width) {
    if (width < compact) return 16;
    if (width < medium) return 24;
    return 32;
  }

  /// How many columns of at least [minTileWidth] fit in [width].
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
