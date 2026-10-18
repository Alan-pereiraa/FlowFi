import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Round back button for app bars. Pair with `AppBar(leadingWidth: 64)`.
/// Falls back to [fallbackRoute] when there is nothing to pop (a deep link or
/// a browser refresh on web).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.fallbackRoute});

  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: IconButton(
        tooltip: 'Voltar',
        style: IconButton.styleFrom(
          backgroundColor: primary.withValues(alpha: 0.08),
        ),
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(fallbackRoute);
          }
        },
      ),
    );
  }
}
