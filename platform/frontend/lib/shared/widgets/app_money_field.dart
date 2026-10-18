import 'package:material_ui/material_ui.dart';

import '../utils/currency_input_formatter.dart';

/// Filled field for an amount in reais, same look as `AppTextField` (label
/// above, theme decoration) with an "R$" prefix and a cents-first mask.
/// Read the value with `CurrencyInputFormatter.centsOf(controller.text)`.
class AppMoneyField extends StatelessWidget {
  const AppMoneyField({
    super.key,
    required this.label,
    this.controller,
    this.hint = '0,00',
    this.helper,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String hint;
  final String? helper;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          inputFormatters: const [CurrencyInputFormatter()],
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperMaxLines: 2,
            errorText: errorText,
            errorMaxLines: 2,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Text(
                'R\$',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
