import 'package:flutter/foundation.dart';

import 'transaction_schedule.dart';
import 'transaction_type.dart';

/// Body of `POST /transactions` (income or expense).
@immutable
class TransactionInput {
  const TransactionInput({
    required this.type,
    required this.categoryId,
    required this.date,
    required this.schedule,
    this.description,
  });

  final TransactionType type;
  final int categoryId;
  final DateTime date;
  final TransactionSchedule schedule;
  final String? description;
}
