import 'package:material_ui/material_ui.dart';

import '../appearance/app_icons.dart';
import '../appearance/app_palette.dart';
import 'app_button.dart';

/// What the picker returns: the icon name and/or `#RRGGBB` color the user
/// settled on. A field is null when the picker did not offer it.
class AppearanceChoice {
  const AppearanceChoice({this.icon, this.color});

  final String? icon;
  final String? color;
}

/// Bottom sheet to choose both an icon and a color, confirmed with "Concluir".
Future<AppearanceChoice?> showAppearanceSheet(
  BuildContext context, {
  String? icon,
  String? color,
}) {
  return _show(
    context,
    icon: icon,
    color: color,
    pickIcon: true,
    pickColor: true,
  );
}

/// Bottom sheet with only the color palette. Returns the chosen `#RRGGBB`.
Future<String?> showColorPickerSheet(
  BuildContext context, {
  String? selected,
}) async {
  final choice = await _show(
    context,
    color: selected,
    pickIcon: false,
    pickColor: true,
  );
  return choice?.color;
}

/// Bottom sheet with only the icon catalog. Returns the chosen icon name.
Future<String?> showIconPickerSheet(
  BuildContext context, {
  String? selected,
  String? tint,
}) async {
  final choice = await _show(
    context,
    icon: selected,
    color: tint,
    pickIcon: true,
    pickColor: false,
  );
  return choice?.icon;
}

Future<AppearanceChoice?> _show(
  BuildContext context, {
  String? icon,
  String? color,
  required bool pickIcon,
  required bool pickColor,
}) {
  return showModalBottomSheet<AppearanceChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // Keeps the sheet a readable column on wide web windows.
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _AppearanceSheet(
      icon: icon,
      color: color,
      pickIcon: pickIcon,
      pickColor: pickColor,
    ),
  );
}

class _AppearanceSheet extends StatefulWidget {
  const _AppearanceSheet({
    required this.icon,
    required this.color,
    required this.pickIcon,
    required this.pickColor,
  });

  final String? icon;
  final String? color;
  final bool pickIcon;
  final bool pickColor;

  @override
  State<_AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends State<_AppearanceSheet> {
  String? _icon;
  String? _color;

  /// One section only: tapping a value closes the sheet at once.
  bool get _single => !(widget.pickIcon && widget.pickColor);

  @override
  void initState() {
    super.initState();
    _icon = widget.icon;
    _color = widget.color;
  }

  void _done() =>
      Navigator.of(context).pop(AppearanceChoice(icon: _icon, color: _color));

  void _selectColor(String hex) {
    setState(() => _color = hex);
    if (_single) _done();
  }

  void _selectIcon(String name) {
    setState(() => _icon = name);
    if (_single) _done();
  }

  String get _title {
    if (!_single) return 'Aparência';
    return widget.pickColor ? 'Escolha uma cor' : 'Escolha um ícone';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = _color == null
        ? theme.colorScheme.primary
        : AppPalette.parse(_color);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (widget.pickColor) ...[
            if (!_single) ...[
              Text('Cor', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final hex in AppPalette.hexes)
                  _Swatch(
                    color: AppPalette.parse(hex),
                    selected: hex == _color?.toUpperCase(),
                    onTap: () => _selectColor(hex),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (widget.pickIcon)
            for (final group in AppIcons.groups) ...[
              Text(group.label, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in group.names)
                    _IconChoice(
                      icon: AppIcons.resolve(name),
                      name: name,
                      tint: tint,
                      selected: name == _icon,
                      onTap: () => _selectIcon(name),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          if (!_single) ...[
            const SizedBox(height: 8),
            AppButton(label: 'Concluir', onPressed: _done),
          ],
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
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
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Cor',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: color,
        shape: CircleBorder(
          side: selected
              ? BorderSide(color: scheme.onSurface, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: selected
                ? Icon(Icons.check, size: 22, color: checkColor)
                : null,
          ),
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.name,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String name;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Ícone ${name.replaceAll('_', ' ')}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? tint.withValues(alpha: 0.14) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? tint : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 48,
            child: Icon(icon, color: selected ? tint : scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
