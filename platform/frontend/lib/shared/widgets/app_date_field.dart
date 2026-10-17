import 'package:material_ui/material_ui.dart';

import '../utils/date_labels.dart';

/// Filled field that opens the date picker. It is read-only on purpose: the
/// picker is localized (pt-BR) and works the same on touch and on desktop web,
/// and it keeps a malformed date from ever being typed.
///
/// A set date can be cleared with the trailing button, which reports `null`.
class AppDateField extends StatefulWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'dd/mm/aaaa',
    this.helper,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String hint;
  final String? helper;
  final String? errorText;

  /// Defaults to today.
  final DateTime? firstDate;

  /// Defaults to 50 years from today.
  final DateTime? lastDate;
  final bool enabled;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late final TextEditingController _controller = TextEditingController(
    text: _textFor(widget.value),
  );

  static String _textFor(DateTime? date) =>
      date == null ? '' : DateLabels.full(date);

  @override
  void didUpdateWidget(AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _textFor(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = widget.firstDate ?? today;
    final last = widget.lastDate ?? DateTime(today.year + 50, 12, 31);

    var initial = widget.value ?? first;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: widget.label,
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller,
          readOnly: true,
          enabled: widget.enabled,
          onTap: widget.enabled ? _pick : null,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 2,
            errorText: widget.errorText,
            errorMaxLines: 2,
            prefixIcon: Icon(
              Icons.calendar_today_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            suffixIcon: widget.value == null || !widget.enabled
                ? null
                : IconButton(
                    tooltip: 'Limpar data',
                    icon: const Icon(Icons.close),
                    onPressed: () => widget.onChanged(null),
                  ),
          ),
        ),
      ],
    );
  }
}
