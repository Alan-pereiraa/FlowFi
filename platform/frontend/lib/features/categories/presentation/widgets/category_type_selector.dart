import 'package:material_ui/material_ui.dart';

import '../../domain/entities/category_type.dart';

class CategoryTypeSelector extends StatelessWidget {
  const CategoryTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.helperText,
  });

  final CategoryType value;
  final ValueChanged<CategoryType>? onChanged;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tipo da categoria',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<CategoryType>(
          showSelectedIcon: false,
          segments: [
            for (final type in CategoryType.values)
              ButtonSegment(value: type, label: Text(type.label)),
          ],
          selected: {value},
          onSelectionChanged: onChanged == null
              ? null
              : (selection) => onChanged!(selection.first),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
