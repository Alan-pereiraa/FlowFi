import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';
import 'transaction_type.dart';

/// How long a monthly recurrence runs.
enum RecurrenceEnd {
  /// A fixed number of occurrences ("Repetir Nx").
  occurrences,

  /// Until a date ("Repetir durante").
  date,

  /// Until the user cancels it ("Até ser cancelado").
  never,
}

/// Body of `POST /recurring-transactions`: [amount] repeats in full every
/// month from [startDate]. Exactly one of [occurrences] / [endDate] is set,
/// or neither for an open-ended recurrence.
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
  });

  final TransactionType type;
  final int? categoryId;
  final int? goalId;
  final Money amount;
  final DateTime startDate;
  final String? description;
  final int? occurrences;
  final DateTime? endDate;
}
