import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/hex_color.dart';
import '../../../categories/domain/entities/category.dart';

/// Horizontal row: "Criar Categoria" first, then one chip per category.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onCreate,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ActionChip(
              avatar: const Icon(Icons.add),
              label: const Text('Criar Categoria'),
              onPressed: onCreate,
              shape: const StadiumBorder(),
            );
          }
          final category = categories[index - 1];
          final selected = category.id == selectedId;
          final color = HexColor.parse(
            category.color,
            fallback: scheme.primary,
          );
          return ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              AppIcons.resolve(category.icon),
              color: selected ? scheme.primary : color,
            ),
            label: Text(category.name),
            selected: selected,
            onSelected: (_) => onSelected(category.id),
            selectedColor: scheme.primary.withValues(alpha: 0.12),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
            labelStyle: TextStyle(
              color: selected ? scheme.primary : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
