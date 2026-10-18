import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/app_palette.dart';
import '../../../../shared/utils/date_labels.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/app_icon_tile.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../domain/entities/goal.dart';

/// One goal in the "Minhas Metas" list: identity, deadline, saved vs. target
/// and progress.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.onTap});

  final Goal goal;

  /// Opens the goal to edit it or add money. Null makes the card static.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = AppPalette.parse(goal.color);

    final saved = Money.format(goal.currentCents, dropZeroCents: true);
    final target = Money.format(goal.targetCents, dropZeroCents: true);
    final deadline = goal.isOpenEnded
        ? 'Meta contínua.'
        : 'Prazo ${DateLabels.monthYear(goal.expiresAt!)}.';

    return Semantics(
      container: true,
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      label: '${goal.name}. $saved de $target. ${goal.percent}% concluído. '
          '$deadline',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
          children: [
            // Soft glow in the corner, tinted by the goal's own color.
            Positioned(
              top: -56,
              right: -56,
              child: IgnorePointer(
                child: Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.14),
                        color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIconTile(
                        icon: AppIcons.resolve(goal.icon),
                        color: color,
                      ),
                      _DatePill(date: goal.expiresAt),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    goal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: saved,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' / $target',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progresso',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${goal.percent}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppProgressBar(value: goal.progress),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Deadline chip: "Dez 2026", or "Contínuo" for a goal with no end date.
class _DatePill extends StatelessWidget {
  const _DatePill({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final openEnded = date == null;
    final foreground = openEnded ? scheme.onSurfaceVariant : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: openEnded
            ? scheme.surfaceContainerHigh
            : scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (openEnded) ...[
            Icon(Icons.all_inclusive, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            openEnded ? 'Contínuo' : DateLabels.monthYear(date!),
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
