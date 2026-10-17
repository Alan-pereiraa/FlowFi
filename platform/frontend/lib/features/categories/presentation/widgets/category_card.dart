import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/app_palette.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/app_icon_tile.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../domain/entities/category.dart';

/// One category, as on the dashboard: icon, name, an "Editar" pill and the
/// limit.
///
/// Without [spentCents] it shows the limit only. With it, it also shows the
/// spent / limit amounts, a progress bar in the category's color, the
/// percentage, and turns red with "Próximo do limite" from 80%.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    this.spentCents,
  });

  final Category category;
  final VoidCallback onEdit;

  /// Spent this month in this category; null when unknown.
  final int? spentCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = AppPalette.parse(category.color);

    final spent = spentCents;
    final nearLimit = spent != null && category.isNearLimit(spent);
    final accent = nearLimit ? scheme.error : color;
    final limitText = category.limitCents == null
        ? 'Sem limite'
        : Money.format(category.limitCents!);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: nearLimit
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
            )
          : null,
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
                  category.limitCents == null
                      ? 'Sem limite mensal'
                      : 'Limite mensal $limitText',
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
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppProgressBar(
                  value: (category.usedPercent(spent) ?? 0) / 100,
                  color: accent,
                ),
                if (nearLimit) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Próximo do limite',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
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
}
