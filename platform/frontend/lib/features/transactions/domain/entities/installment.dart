import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';

enum InstallmentStatus { pending, paid }

@immutable
class Installment {
  const Installment({
    required this.id,
    required this.step,
    required this.amount,
    required this.status,
    required this.date,
    this.paidAt,
  });

  final int id;

  final int step;
  final Money amount;
  final InstallmentStatus status;

  final DateTime date;
  final DateTime? paidAt;

  bool get isPaid => status == InstallmentStatus.paid;

  bool isOverdueOn(DateTime today) =>
      !isPaid && date.isBefore(DateTime(today.year, today.month, today.day));

  @override
  bool operator ==(Object other) =>
      other is Installment &&
      other.id == id &&
      other.step == step &&
      other.amount == amount &&
      other.status == status &&
      other.date == date &&
      other.paidAt == paidAt;

  @override
  int get hashCode => Object.hash(id, step, amount, status, date, paidAt);
}
