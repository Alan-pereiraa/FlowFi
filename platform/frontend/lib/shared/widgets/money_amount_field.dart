import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../money/money.dart';
import '../utils/currency_input_formatter.dart';

class MoneyAmountField extends StatefulWidget {
  const MoneyAmountField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.color,
    this.step,
    this.enabled = true,
    this.errorText,
  });

  final Money value;
  final ValueChanged<Money> onChanged;
  final String? label;

  final Color? color;
  final Money? step;
  final bool enabled;
  final String? errorText;

  static const maxDigits = 10;

  @override
  State<MoneyAmountField> createState() => _MoneyAmountFieldState();
}

class _MoneyAmountFieldState extends State<MoneyAmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value.formatDigits(),
  );

  @override
  void didUpdateWidget(MoneyAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value.formatDigits();
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    widget.onChanged(Money(digits.isEmpty ? 0 : int.parse(digits)));
  }

  void _stepBy(int sign) {
    final next = Money(widget.value.cents + sign * widget.step!.cents);
    if (next.cents < 0) return;
    if (next.cents.toString().length > MoneyAmountField.maxDigits) return;
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;
    final amountStyle = theme.textTheme.displaySmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w800,
    );
    final symbolStyle = theme.textTheme.titleLarge?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
    );

    final field = IntrinsicWidth(
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: amountStyle,
        inputFormatters: [_CentsInputFormatter()],
        onChanged: _onTextChanged,
        decoration: const InputDecoration(
          filled: false,
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

    return Semantics(
      label: widget.label ?? 'Valor',
      child: Column(
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('R\$', style: symbolStyle),
              const SizedBox(width: 16),
              if (widget.step != null)
                IconButton(
                  tooltip: 'Diminuir',
                  color: color,
                  iconSize: 32,
                  onPressed: widget.enabled ? () => _stepBy(-1) : null,
                  icon: const Icon(Icons.remove),
                ),
              Flexible(child: field),
              if (widget.step != null)
                IconButton(
                  tooltip: 'Aumentar',
                  color: color,
                  iconSize: 32,
                  onPressed: widget.enabled ? () => _stepBy(1) : null,
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorText!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CentsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = CurrencyInputFormatter.editedDigits(oldValue, newValue);
    if (digits.length > MoneyAmountField.maxDigits) return oldValue;
    final text = Money(digits.isEmpty ? 0 : int.parse(digits)).formatDigits();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
