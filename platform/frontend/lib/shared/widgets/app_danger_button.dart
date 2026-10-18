import 'package:material_ui/material_ui.dart';

/// Full-width destructive action ("Remover", "Excluir") in the theme's error
/// container colors, with a built-in loading state.
class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.remove_circle_outline,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.error,
        disabledBackgroundColor: scheme.errorContainer.withValues(alpha: 0.5),
        disabledForegroundColor: scheme.error.withValues(alpha: 0.6),
      ),
      icon: loading
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.error,
              ),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}
