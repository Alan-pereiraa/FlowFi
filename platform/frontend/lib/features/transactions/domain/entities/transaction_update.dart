import 'package:flutter/foundation.dart';

import 'transaction_schedule.dart';

@immutable
class TransactionUpdate {
  const TransactionUpdate({
    required this.date,
    this.categoryId,
    this.goalId,
    this.description,
    this.schedule,
  });

  final int? categoryId;
  final int? goalId;
  final DateTime date;

  final String? description;

  final TransactionSchedule? schedule;
}
