import 'package:material_ui/material_ui.dart';

/// An outlined row with a radio dot, as in the design's "Transação
/// Parcelada" and the "Repetir ..." options. Tapping it selects it; for a
/// standalone option (parcelada) tapping again deselects.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool selected;

  /// Null disables the row.
  final VoidCallback? onTap;

  /// A small control on the right (e.g. the "1x" pill or a calendar button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Material(
          color: scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: subtitle == null ? 8 : 10,
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: subtitle == null
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The small outlined pill on the right of a [ChoiceRow] ("1x", calendar).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.tooltip,
  });

  final String? label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(40, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
        shape: const StadiumBorder(),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
      ),
      child: icon != null ? Icon(icon, size: 20) : Text(label ?? ''),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}
