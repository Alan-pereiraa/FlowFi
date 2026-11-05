import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/hex_color.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/installment.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

// GAP: the design's account ("Conta Corrente • ...") and time of day have no
// backend field.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.installment,
    this.category,
    this.onTap,
    this.onPay,
    this.paying = false,
  });

  final Transaction transaction;
  final Installment? installment;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onPay;
  final bool paying;

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
      if (installment != null && transaction.installmentsCount > 1)
        '${installment!.step}/${transaction.installmentsCount}',
      if (installment != null) installment!.isPaid ? 'Paga' : 'Pendente',
    ].whereType<String>().join(' • ');

    final pending = onPay != null && installment?.isPaid == false;

    final amount = (installment?.amount ?? transaction.totalAmount).format();
    final (signed, amountColor) = switch (type) {
      TransactionType.expense => ('- $amount', scheme.onSurface),
      TransactionType.income => ('+ $amount', success),
      TransactionType.transfer => (amount, scheme.onSurfaceVariant),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                              : (type == TransactionType.transfer
                                    ? 'Transferência'
                                    : category?.name ?? 'Transação'),
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
                  if (transaction.isRecurring) ...[
                    Tooltip(
                      message: 'Transação recorrente',
                      child: Icon(
                        Icons.autorenew,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    signed,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (pending) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: paying ? null : onPay,
                    icon: paying
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Pagar'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
