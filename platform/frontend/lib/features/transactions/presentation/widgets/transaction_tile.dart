import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/hex_color.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

/// One statement row: category icon, description, category and signed
/// amount (`-` in error for expenses, `+` in success for income).
// GAP: the design's account ("Conta Corrente • ...") and time of day have no
// backend field.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
  });

  final Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = theme.extension<AppColors>()!.success;
    final type = transaction.type;

    final accent = type == TransactionType.transfer
        ? scheme.primary
        : HexColor.parse(category?.color, fallback: scheme.onSurfaceVariant);
    final icon = type == TransactionType.transfer
        ? Icons.savings
        : AppIcons.resolve(category?.icon);
    final subtitle = [
      type == TransactionType.transfer
          ? 'Transferência para meta'
          : category?.name,
      if (transaction.installmentsCount > 1)
        '${transaction.installmentsCount}x',
    ].whereType<String>().join(' • ');

    final amount = transaction.totalAmount.format();
    final (signed, amountColor) = switch (type) {
      TransactionType.expense => ('- $amount', scheme.error),
      TransactionType.income => ('+ $amount', success),
      TransactionType.transfer => (amount, scheme.onSurfaceVariant),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accent.withValues(alpha: 0.16),
                foregroundColor: accent,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description?.trim().isNotEmpty == true
                          ? transaction.description!
                          : (category?.name ?? 'Transação'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
          ),
        ),
      ),
    );
  }
}
