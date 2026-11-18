import 'package:material_ui/material_ui.dart';

import '../../../../shared/money/money.dart';
import '../../../../shared/utils/dates.dart';
import '../../../categories/domain/entities/category.dart';

class CategoryUsageHint extends StatelessWidget {
  const CategoryUsageHint({
    super.key,
    required this.category,
    required this.usedCents,
    required this.amountCents,
    required this.month,
  });

  final Category category;
  final int usedCents;
  final int amountCents;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final limit = category.limitCents;
    if (limit == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final period = Dates.monthYear(month);
    final limitText = Money(limit).format();

    final String text;
    var warn = false;
    if (category.isIncome) {
      text =
          'Recebido ${Money(usedCents).format()} de $limitText da meta em $period.';
    } else if (usedCents >= limit) {
      warn = true;
      text = 'O limite de $limitText já foi atingido em $period.';
    } else {
      final remaining = limit - usedCents;
      warn = amountCents > remaining;
      text = warn
          ? 'Este valor passa do limite: restam ${Money(remaining).format()} de $limitText em $period.'
          : 'Restam ${Money(remaining).format()} de $limitText em $period.';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warn ? Icons.warning_amber_rounded : Icons.info_outline,
            size: 16,
            color: warn ? scheme.error : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: warn ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
