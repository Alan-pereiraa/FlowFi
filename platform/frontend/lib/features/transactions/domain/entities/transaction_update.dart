import 'package:flutter/foundation.dart';

import 'transaction_schedule.dart';

/// Body of `PATCH /transactions/{id}`. `type` is immutable, so it isn't here.
/// Income and expense send [categoryId]; a transfer sends [goalId].
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

  /// Null clears it.
  final String? description;

  /// Sent only when the amount or duration changed: any schedule field makes
  /// the backend re-plan every installment, which is refused (422) once one
  /// is paid.
  final TransactionSchedule? schedule;
}
