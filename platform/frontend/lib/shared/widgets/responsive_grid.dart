import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../layout/breakpoints.dart';

/// Equal-height card grid whose column count follows the width it is given
/// (1 on a phone, up to [maxColumns] on desktop). Rows size to their content,
/// so large text scales never overflow a fixed tile height.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.minTileWidth = 320,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double spacing;
  final double minTileWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Breakpoints.columnsFor(
          constraints.maxWidth,
          minTileWidth: minTileWidth,
          spacing: spacing,
          maxColumns: maxColumns,
        );

        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          final end = math.min(start + columns, children.length);
          final slice = children.sublist(start, end);
          rows.add(
            columns == 1
                ? slice.first
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++) ...[
                          if (i > 0) SizedBox(width: spacing),
                          Expanded(
                            child: i < slice.length
                                ? slice[i]
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}
