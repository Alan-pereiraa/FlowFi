import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../shared/utils/currency_input_formatter.dart';

/// The big "R$  −  00,00  +" limit control. The number can be typed (cents
/// first, same mask as the money fields) or nudged with − and +.
class LimitStepper extends StatefulWidget {
  const LimitStepper({
    super.key,
    required this.cents,
    required this.onChanged,
    required this.caption,
    this.captionBelow = false,
    this.errorText,
    this.step = 5000,
    this.enabled = true,
  });

  final int cents;
  final ValueChanged<int> onChanged;

  /// "Adicionar Limite" / "Editar Limite".
  final String caption;

  /// The edit design puts the caption under the number; the add design puts
  /// it above.
  final bool captionBelow;
  final String? errorText;

  /// How much − and + move the value, in cents (R$ 50,00 by default).
  final int step;
  final bool enabled;

  @override
  State<LimitStepper> createState() => _LimitStepperState();
}

class _LimitStepperState extends State<LimitStepper> {
  late final TextEditingController _controller = TextEditingController(
    text: CurrencyInputFormatter.textOf(widget.cents),
  );

  @override
  void didUpdateWidget(LimitStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Typing already keeps the controller in sync; this only reacts to − / +.
    if (CurrencyInputFormatter.centsOf(_controller.text) != widget.cents) {
      final text = CurrencyInputFormatter.textOf(widget.cents);
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

  void _nudge(int delta) {
    final next = widget.cents + delta;
    widget.onChanged(
      math.max(0, math.min(CurrencyInputFormatter.maxCents, next)),
    );
  }

  /// Slider range when the limit is small; it grows to fit a bigger typed value.
  static const _sliderBaseMax = 500000; // R$ 5.000,00

  Widget _limitSlider(BuildContext context) {
    final step = widget.step;
    final fitsValue = ((widget.cents + step - 1) ~/ step) * step;
    final max = math.max(_sliderBaseMax, fitsValue);

    return Slider(
      value: widget.cents.toDouble(),
      max: max.toDouble(),
      divisions: max ~/ step,
      label: 'R\$ ${CurrencyInputFormatter.textOf(widget.cents)}',
      semanticFormatterCallback: (value) =>
          'R\$ ${CurrencyInputFormatter.textOf(value.round())}',
      onChanged: widget.enabled
          ? (value) => widget.onChanged(value.round())
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final caption = Text(
      widget.caption,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
    );
    final amountStyle = theme.textTheme.displaySmall?.copyWith(
      color: scheme.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.captionBelow) ...[caption, const SizedBox(height: 16)],
        Row(
          children: [
            Text(
              'R\$',
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            _StepButton(
              icon: Icons.remove,
              tooltip: 'Diminuir limite',
              onPressed: widget.enabled && widget.cents > 0
                  ? () => _nudge(-widget.step)
                  : null,
            ),
            Expanded(
              child: Semantics(
                label: widget.caption,
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CurrencyInputFormatter()],
                  onChanged: (text) =>
                      widget.onChanged(CurrencyInputFormatter.centsOf(text)),
                  cursorColor: scheme.primary,
                  style: amountStyle,
                  // The theme's field is filled and outlined; this one is bare.
                  decoration: InputDecoration(
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: '00,00',
                    hintStyle: amountStyle,
                  ),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              tooltip: 'Aumentar limite',
              onPressed: widget.enabled ? () => _nudge(widget.step) : null,
            ),
          ],
        ),
        if (widget.captionBelow) ...[const SizedBox(height: 4), caption],
        const SizedBox(height: 8),
        _limitSlider(context),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ] else if (widget.cents == 0) ...[
          const SizedBox(height: 8),
          Text(
            'Deixe em 00,00 para não definir um limite.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 32,
      color: Theme.of(context).colorScheme.primary,
      icon: Icon(icon),
    );
  }
}
