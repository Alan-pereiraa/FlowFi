import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';
import 'transaction_type.dart';

@immutable
class TransactionDraft {
  const TransactionDraft({
    required this.transcript,
    required this.recurring,
    required this.type,
    this.amount,
    this.date,
    this.description,
    this.categoryId,
    this.goalId,
    this.installmentsCount,
    this.periodUnit,
    this.periodInterval,
    this.occurrences,
    this.endDate,
  });

  final String transcript;
  final bool recurring;
  final TransactionType type;
  final Money? amount;
  final DateTime? date;
  final String? description;
  final int? categoryId;
  final int? goalId;
  final int? installmentsCount;
  final String? periodUnit;
  final int? periodInterval;
  final int? occurrences;
  final DateTime? endDate;

  bool get movesGoal => type.movesGoal;

  bool get missingAmount => amount == null || amount!.isZero;

  bool get missingGoal => movesGoal && goalId == null;

  int get missingCount => [missingAmount, missingGoal].where((m) => m).length;
}
