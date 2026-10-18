import 'package:material_ui/material_ui.dart';

import '../layout/breakpoints.dart';

/// Page body that is full-bleed on phones and a centered column on wide
/// screens, with side padding that grows with the viewport.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMax,
    this.verticalPadding = 0,
  });

  final Widget child;
  final double maxWidth;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = Breakpoints.pagePadding(constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth + horizontal * 2),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: verticalPadding,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
