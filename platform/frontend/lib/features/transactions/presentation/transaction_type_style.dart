import 'package:material_ui/material_ui.dart';

import '../../../shared/theme/app_colors.dart';
import '../domain/entities/transaction_type.dart';

extension TransactionTypeStyle on TransactionType {
  Color color(ThemeData theme) => switch (this) {
    TransactionType.expense => theme.colorScheme.error,
    TransactionType.income => theme.extension<AppColors>()!.success,
    TransactionType.transfer => theme.colorScheme.primary,
    TransactionType.withdrawal => theme.colorScheme.tertiary,
  };

  IconData get icon => switch (this) {
    TransactionType.expense => Icons.north_east,
    TransactionType.income => Icons.south_west,
    TransactionType.transfer => Icons.savings,
    TransactionType.withdrawal => Icons.account_balance_wallet,
  };

  String get label => switch (this) {
    TransactionType.expense => 'Saída',
    TransactionType.income => 'Entrada',
    TransactionType.transfer => 'Transferência',
    TransactionType.withdrawal => 'Resgate',
  };
}
