import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';
import 'transaction_type.dart';

enum RecurrenceEnd { occurrences, date, never }

@immutable
class RecurringInput {
  const RecurringInput({
    required this.type,
    required this.amount,
    required this.startDate,
    this.categoryId,
    this.goalId,
    this.description,
    this.occurrences,
    this.endDate,
    this.periodUnit = 'month',
    this.periodInterval = 1,
  });

  final TransactionType type;
  final int? categoryId;
  final int? goalId;
  final Money amount;
  final DateTime startDate;
  final String? description;
  final int? occurrences;
  final DateTime? endDate;
  final String periodUnit;
  final int periodInterval;
}
