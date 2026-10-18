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
  final List<Installment> installments;

  /// The backend freezes the schedule (amount, recurrence, duration) once
  /// any installment is paid.
  bool get hasPaidInstallment => installments.any((i) => i.isPaid);

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
    Object.hashAll(installments),
  );
}
