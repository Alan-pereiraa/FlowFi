import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Filled text field with the label above it and an optional leading icon.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.icon,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? icon;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Replaces [icon] when the leading slot needs to be interactive.
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;

  /// For fields filled by a picker ([onTap]) instead of the keyboard.
  final bool readOnly;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        errorMaxLines: 2,
        prefixIcon:
            prefix ??
            (icon == null
                ? null
                : Icon(icon, color: theme.colorScheme.onSurfaceVariant)),
        suffixIcon: suffix,
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
