import 'package:flutter/foundation.dart';

import 'transaction_schedule.dart';
import 'transaction_type.dart';

@immutable
class TransactionInput {
  const TransactionInput({
    required this.type,
    required this.date,
    required this.schedule,
    this.categoryId,
    this.goalId,
    this.description,
  });

  final TransactionType type;
  final int? categoryId;
  final int? goalId;
  final DateTime date;
  final TransactionSchedule schedule;
  final String? description;
}
