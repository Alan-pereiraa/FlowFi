import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/app_palette.dart';
import '../../../../shared/utils/date_labels.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/app_icon_tile.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../../../shared/widgets/responsive_grid.dart';
import '../../domain/entities/goal_creation.dart';
import '../goal_routes.dart';

/// "Meta criada com sucesso!". Lives inside the app shell, so it has no
/// `Scaffold`.
// GAP: the design lists a "Categoria" row, but goals have no category in the
// API. It is left out rather than invented. "Contribuição Mensal" is derived
// on the client from the target, what is saved and the deadline.
class GoalCreatedPage extends StatelessWidget {
  const GoalCreatedPage({super.key, required this.creation});

  final GoalCreation creation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      child: ResponsiveCenter(
        maxWidth: 560,
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(
                Icons.check_circle_outline,
                size: 96,
                color: scheme.primary,
                semanticLabel: 'Sucesso',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Meta criada com sucesso!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Sua nova meta foi criada e está pronta para te ajudar a '
              'alcançar seus objetivos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _SummaryCard(creation: creation),
            if (creation.initialDepositFailed) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 18, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Não foi possível registrar o valor inicial. A meta '
                      'foi criada com saldo zero.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'O que deseja fazer agora?',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ResponsiveGrid(
              minTileWidth: 240,
              maxColumns: 2,
              children: [
                _ActionCard(
                  icon: Icons.track_changes_outlined,
                  title: 'Ver minhas metas',
                  message:
                      'Acompanhe o progresso de todas as suas metas '
                      'financeiras.',
                  onTap: () => context.go(Routes.goals),
                ),
                _ActionCard(
                  icon: Icons.add,
                  title: 'Criar outra meta',
                  message:
                      'Defina um novo objetivo financeiro para continuar '
                      'planejando seu futuro.',
                  onTap: () => context.go(GoalRoutes.create),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.creation});

  final GoalCreation creation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = creation.goal;
    final monthly = goal.monthlyContributionCents(DateTime.now());
    final saved = Money.format(goal.currentCents, dropZeroCents: true);
    final target = Money.format(goal.targetCents, dropZeroCents: true);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIconTile(
                  icon: AppIcons.resolve(goal.icon),
                  color: AppPalette.parse(goal.color),
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SummaryRow(label: 'Valor da Meta', value: target),
            _SummaryRow(
              label: 'Data Alvo',
              value: goal.expiresAt == null
                  ? 'Contínua'
                  : DateLabels.monthYear(goal.expiresAt!),
            ),
            _SummaryRow(label: 'Valor Inicial', value: saved),
            if (monthly != null)
              _SummaryRow(
                label: 'Contribuição Mensal',
                value: Money.format(monthly),
              ),
            const SizedBox(height: 12),
            AppProgressBar(value: goal.progress),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  saved,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  target,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
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
