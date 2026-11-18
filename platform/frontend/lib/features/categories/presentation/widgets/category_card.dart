import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/app_palette.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/app_icon_tile.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../domain/entities/category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    this.spentCents,
  });

  final Category category;
  final VoidCallback onEdit;

  final int? spentCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = AppPalette.parse(category.color);

    final spent = spentCents;
    final overLimit = spent != null && category.isOverLimit(spent);
    final accent = color;
    final usageColor = overLimit ? scheme.error : accent;
    final limitText = category.limitCents == null
        ? (category.isIncome ? 'Sem meta' : 'Sem limite')
        : Money.format(category.limitCents!);
    final status = spent == null ? null : _status(spent, scheme, accent);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppIconTile(
                    icon: AppIcons.resolve(category.icon),
                    color: accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      visualDensity: VisualDensity.compact,
                      shape: const StadiumBorder(),
                      textStyle: theme.textTheme.labelMedium,
                    ),
                    child: const Text('Editar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (spent == null)
                Text(
                  switch ((category.isIncome, category.limitCents == null)) {
                    (true, true) => 'Sem meta mensal',
                    (true, false) => 'Meta mensal $limitText',
                    (false, true) => 'Sem limite mensal',
                    (false, false) => 'Limite mensal $limitText',
                  },
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: Money.format(spent),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: ' / $limitText',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.usedPercent(spent) == null
                          ? '--'
                          : '${category.usedPercent(spent)}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: usageColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppProgressBar(
                  value: (category.usedPercent(spent) ?? 0) / 100,
                  color: usageColor,
                ),
                if (status != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(status.icon, size: 16, color: status.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          status.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  _CardStatus? _status(int spent, ColorScheme scheme, Color accent) {
    if (category.reachedGoal(spent)) {
      return (
        icon: Icons.check_circle_rounded,
        color: accent,
        label: 'Meta atingida',
      );
    }
    if (category.isOverLimit(spent)) {
      return (
        icon: Icons.error_rounded,
        color: scheme.error,
        label:
            'Limite estourado em ${Money.format(spent - category.limitCents!)}',
      );
    }
    if (category.isAtLimit(spent)) {
      return (
        icon: Icons.warning_amber_rounded,
        color: scheme.error,
        label: 'Limite atingido',
      );
    }
    if (category.isNearLimit(spent)) {
      return (
        icon: Icons.warning_amber_rounded,
        color: scheme.error,
        label: 'Próximo do limite',
      );
    }
    return null;
  }
}

typedef _CardStatus = ({IconData icon, Color color, String label});
