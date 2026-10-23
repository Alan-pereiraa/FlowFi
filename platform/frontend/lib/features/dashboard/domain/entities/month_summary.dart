import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';
import 'money_flow.dart';

@immutable
class MonthSummary {
  const MonthSummary({
    required this.month,
    required this.income,
    required this.expense,
    required this.projectedBalance,
  });

  final DateTime month;
  final MoneyFlow income;
  final MoneyFlow expense;
  final Money projectedBalance;

  int? get incomeUsedPercent {
    final income = this.income.total.cents;
    if (income <= 0) return null;
    return (expense.total.cents * 100) ~/ income;
  }

  @override
  bool operator ==(Object other) =>
      other is MonthSummary &&
      other.month == month &&
      other.income == income &&
      other.expense == expense &&
      other.projectedBalance == projectedBalance;

  @override
  int get hashCode => Object.hash(month, income, expense, projectedBalance);
}
