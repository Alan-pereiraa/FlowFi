import 'package:material_ui/material_ui.dart';

import 'app_icons.dart';
import 'hex_color.dart';

/// Bottom sheets to pick a category/goal color (`#RRGGBB`) or icon name.
/// Both return null when dismissed.
abstract final class AppearancePicker {
  static Future<String?> pickColor(BuildContext context, {String? selected}) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escolha uma cor',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final hex in HexColor.palette)
                    _ColorSwatch(
                      color: HexColor.tryParse(hex)!,
                      selected: hex == selected,
                      onTap: () => Navigator.of(context).pop(hex),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<String?> pickIcon(
    BuildContext context, {
    String? selected,
    Color? color,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final accent = color ?? scheme.primary;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) => GridView.extent(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            maxCrossAxisExtent: 64,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final group in AppIcons.groupsByKey.values)
                for (final MapEntry(key: name, value: icon) in group.entries)
                  IconButton(
                    tooltip: name,
                    isSelected: name == selected,
                    style: IconButton.styleFrom(
                      backgroundColor: name == selected
                          ? accent.withValues(alpha: 0.16)
                          : null,
                    ),
                    color: name == selected ? accent : scheme.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(name),
                    icon: Icon(icon),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Cor',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: scheme.onSurface, width: 3)
                : null,
          ),
          child: selected
              ? Icon(Icons.check, color: scheme.surfaceContainerLowest)
              : null,
        ),
      ),
    );
  }
}
