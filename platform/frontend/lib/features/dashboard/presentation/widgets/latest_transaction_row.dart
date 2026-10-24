import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/hex_color.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/dates.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
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
    final success = theme.extension<AppColors>()!.success;
    final type = transaction.type;
    final isTransfer = type == TransactionType.transfer;
    final tag = isTransfer ? transaction.goal : transaction.category;

    final accent = HexColor.parse(
      tag?.color,
      fallback: isTransfer ? scheme.primary : scheme.onSurfaceVariant,
    );
    final icon = tag == null && isTransfer
        ? Icons.savings
        : AppIcons.resolve(tag?.icon);
    final description = transaction.description?.trim() ?? '';
    final title = description.isNotEmpty
        ? description
        : tag?.name ?? (isTransfer ? 'Transferência para meta' : 'Transação');

    final amount = transaction.totalAmount.format();
    final (signed, amountColor) = switch (type) {
      TransactionType.expense => ('- $amount', scheme.error),
      TransactionType.income => ('+ $amount', success),
      TransactionType.transfer => (amount, scheme.onSurfaceVariant),
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
                Dates.shortDay(transaction.date, today: today),
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
