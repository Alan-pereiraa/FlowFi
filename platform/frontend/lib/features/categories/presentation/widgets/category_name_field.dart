import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/app_palette.dart';

/// Category name field with its two appearance controls built in, as in the
/// design: a color dot at the start (opens the palette) and an icon button at
/// the end (opens the icon catalog).
///
/// `AppTextField` only takes a plain icon as prefix, so this field builds its
/// own decoration from the same theme.
class CategoryNameField extends StatelessWidget {
  const CategoryNameField({
    super.key,
    required this.label,
    required this.controller,
    required this.color,
    required this.icon,
    required this.onPickColor,
    required this.onPickIcon,
    this.hint,
    this.errorText,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;

  /// `#RRGGBB`, or null while the user has not chosen one.
  final String? color;

  /// Icon name, or null while the user has not chosen one.
  final String? icon;
  final VoidCallback onPickColor;
  final VoidCallback onPickIcon;
  final String? hint;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            errorMaxLines: 2,
            prefixIcon: IconButton(
              tooltip: 'Escolher cor',
              onPressed: enabled ? onPickColor : null,
              icon: _ColorDot(hex: color),
            ),
            suffixIcon: IconButton(
              tooltip: 'Escolher ícone',
              onPressed: enabled ? onPickIcon : null,
              icon: Icon(
                icon == null
                    ? Icons.sentiment_satisfied_alt_outlined
                    : AppIcons.resolve(icon),
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The chosen color, or a color wheel while none is chosen.
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});

  final String? hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hex == null ? null : AppPalette.parse(hex),
        gradient: hex == null
            ? const SweepGradient(colors: AppPalette.wheel)
            : null,
      ),
    );
  }
}
