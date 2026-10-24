import 'package:material_ui/material_ui.dart';

import '../../../../shared/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../domain/entities/month_summary.dart';

class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({super.key, required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<AppColors>()!;
    final onHero = scheme.onPrimary;
    final muted = onHero.withValues(alpha: 0.8);

    final spent = summary.expense.total.format();
    final income = summary.income.total.format();
    final percent = summary.incomeUsedPercent;
    final usage = percent == null ? 'Sem entradas no mês' : '$percent% de uso';
    final left = summary.projectedBalance;
    final remaining = left.cents < 0
        ? '${Money(-left.cents).format()} acima das entradas'
        : '${left.format()} restantes';
    final overspent = left.cents < 0;

    final barValue = percent == null
        ? (summary.expense.total.cents > 0 ? 1.0 : 0.0)
        : percent / 100;

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: muted,
      letterSpacing: 1,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'Total gasto no mês: $spent. Valor total de entradas: $income. '
          '$usage. $remaining.',
      child: Container(
        decoration: BoxDecoration(
          gradient: colors.heroGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL GASTO NO MÊS', style: labelStyle),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          spent,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: onHero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('VALOR TOTAL', style: labelStyle),
                    const SizedBox(height: 4),
                    Text(
                      income,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onHero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppProgressBar(
              value: barValue,
              color: overspent ? scheme.errorContainer : onHero,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    usage,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    remaining,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overspent ? scheme.errorContainer : muted,
                      fontWeight: overspent ? FontWeight.w600 : null,
                    ),
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
