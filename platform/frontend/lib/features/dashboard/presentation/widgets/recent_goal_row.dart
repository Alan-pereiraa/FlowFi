import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/app_palette.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/app_icon_tile.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../goals/domain/entities/goal.dart';

class RecentGoalRow extends StatelessWidget {
  const RecentGoalRow({super.key, required this.goal, this.onTap});

  final Goal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = Money.format(goal.currentCents, dropZeroCents: true);
    final target = Money.format(goal.targetCents, dropZeroCents: true);

    return Semantics(
      container: true,
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      label: '${goal.name}. $saved de $target. ${goal.percent}% concluído.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppIconTile(
                    icon: AppIcons.resolve(goal.icon),
                    color: AppPalette.parse(goal.color),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$saved / $target',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppProgressBar(value: goal.progress),
            ],
          ),
        ),
      ),
    );
  }
}
