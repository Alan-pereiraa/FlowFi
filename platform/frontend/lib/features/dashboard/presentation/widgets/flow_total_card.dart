import 'package:material_ui/material_ui.dart';

import '../../../../shared/money/money.dart';

class FlowTotalCard extends StatelessWidget {
  const FlowTotalCard.income({super.key, required this.amount})
    : isIncome = true;

  const FlowTotalCard.expense({super.key, required this.amount})
    : isIncome = false;

  final Money amount;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isIncome ? scheme.primary : scheme.error;
    final label = isIncome ? 'ENTRADAS' : 'SAÍDAS';
    final value = amount.format();

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '${isIncome ? 'Entradas' : 'Saídas'} do mês: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
