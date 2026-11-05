import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';
import 'installment.dart';
import 'transaction_type.dart';

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.date,
    required this.totalAmount,
    required this.installmentsCount,
    this.categoryId,
    this.goalId,
    this.description,
    this.periodUnit,
    this.periodInterval,
    this.recurringTransactionId,
    this.installments = const [],
  });

  final int id;

  /// Null only for transfers.
  final int? categoryId;
  final int? goalId;
  final TransactionType type;
  final String? description;
  final DateTime date;
  final Money totalAmount;
  final int installmentsCount;

  /// `day` | `week` | `month` | `year`; null for a single installment.
  final String? periodUnit;
  final int? periodInterval;

  final int? recurringTransactionId;
  final List<Installment> installments;

  bool get isRecurring => recurringTransactionId != null;

  Transaction withInstallment(Installment updated) => Transaction(
    id: id,
    type: type,
    date: date,
    totalAmount: totalAmount,
    installmentsCount: installmentsCount,
    categoryId: categoryId,
    goalId: goalId,
    description: description,
    periodUnit: periodUnit,
    periodInterval: periodInterval,
    recurringTransactionId: recurringTransactionId,
    installments: [
      for (final installment in installments)
        installment.id == updated.id ? updated : installment,
    ],
  );

  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.categoryId == categoryId &&
      other.goalId == goalId &&
      other.type == type &&
      other.description == description &&
      other.date == date &&
      other.totalAmount == totalAmount &&
      other.installmentsCount == installmentsCount &&
      other.periodUnit == periodUnit &&
      other.periodInterval == periodInterval &&
      other.recurringTransactionId == recurringTransactionId &&
      listEquals(other.installments, installments);

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    goalId,
    type,
    description,
    date,
    totalAmount,
    installmentsCount,
    periodUnit,
    periodInterval,
    recurringTransactionId,
    Object.hashAll(installments),
  );
}
