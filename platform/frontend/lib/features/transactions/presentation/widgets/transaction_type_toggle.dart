import 'package:material_ui/material_ui.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../domain/entities/transaction_type.dart';

/// `Saída` / `Entrada` segmented toggle. Disabled on edit: the type is
/// immutable on the backend.
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TransactionType value;

  /// Null disables the toggle.
  final ValueChanged<TransactionType>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onChanged == null ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary),
        ),
        child: Row(
          children: [
            Expanded(
              child: _Segment(
                label: 'Saída',
                selected: value == TransactionType.expense,
                background: scheme.errorContainer,
                foreground: scheme.error,
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(TransactionType.expense),
              ),
            ),
            Expanded(
              child: _Segment(
                label: 'Entrada',
                selected: value == TransactionType.income,
                background: Theme.of(context)
                    .extension<AppColors>()!
                    .success
                    .withValues(alpha: 0.16),
                foreground: scheme.primary,
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(TransactionType.income),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: Material(
        color: selected ? background : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected ? foreground : theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
