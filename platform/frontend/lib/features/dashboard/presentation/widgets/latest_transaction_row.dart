import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/utils/dates.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/presentation/transaction_type_style.dart';
import '../../domain/entities/recent_transaction.dart';

class LatestTransactionRow extends StatelessWidget {
  const LatestTransactionRow({
    super.key,
    required this.transaction,
    required this.today,
  });

  final RecentTransaction transaction;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final type = transaction.type;
    final tag = type.movesGoal ? transaction.goal : transaction.category;

    final accent = type.color(theme);
    final icon = tag == null ? type.icon : AppIcons.resolve(tag.icon);
    final description = transaction.description?.trim() ?? '';
    final title = description.isNotEmpty
        ? description
        : tag?.name ??
              switch (type) {
                TransactionType.transfer => 'Transferência para meta',
                TransactionType.withdrawal => 'Resgate da meta',
                _ => type.label,
              };
    final detail = [
      type.label,
      if (!type.movesGoal) transaction.category?.name ?? 'Sem categoria',
      Dates.shortDay(transaction.date, today: today),
    ].join(' • ');

    final amount = transaction.totalAmount.format();
    final (signed, amountColor) = switch (type) {
      TransactionType.expense => ('- $amount', accent),
      TransactionType.income => ('+ $amount', accent),
      TransactionType.transfer ||
      TransactionType.withdrawal => (amount, scheme.onSurfaceVariant),
    };

    return Row(
      children: [
        ExcludeSemantics(
          child: CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.16),
            foregroundColor: accent,
            child: Icon(icon, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          signed,
          style: theme.textTheme.titleSmall?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
