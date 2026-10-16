import 'package:material_ui/material_ui.dart';

/// "Transação Recorrente" card with its switch.
class RecurrenceCard extends StatelessWidget {
  const RecurrenceCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: MergeSemantics(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          enabled: onChanged != null,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: scheme.surfaceContainerHighest,
            foregroundColor: scheme.primary,
            child: const Icon(Icons.autorenew),
          ),
          title: Text(
            'Transação Recorrente',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Repetir mensalmente',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          trailing: Switch(value: value, onChanged: onChanged),
        ),
      ),
    );
  }
}
