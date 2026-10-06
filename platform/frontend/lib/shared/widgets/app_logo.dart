import 'package:material_ui/material_ui.dart';

/// FlowFi wordmark.
// GAP: the design uses an image logo; no asset exported yet, so this renders
// a text wordmark. Swap for the asset once it is in `assets/`.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'FlowFi',
      excludeSemantics: true,
      child: Text(
        'FlowFi',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: size,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
