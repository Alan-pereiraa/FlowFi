import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import 'dashboard_tag.dart';

@immutable
class RecentTransaction {
  const RecentTransaction({
    required this.id,
    required this.type,
    required this.date,
    required this.totalAmount,
    required this.installmentsCount,
    this.description,
    this.category,
    this.goal,
  });

  final int id;
  final TransactionType type;
  final String? description;
  final DateTime date;
  final Money totalAmount;
  final int installmentsCount;
  final DashboardTag? category;
  final DashboardTag? goal;

  @override
  bool operator ==(Object other) =>
      other is RecentTransaction &&
      other.id == id &&
      other.type == type &&
      other.description == description &&
      other.date == date &&
      other.totalAmount == totalAmount &&
      other.installmentsCount == installmentsCount &&
      other.category == category &&
      other.goal == goal;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    description,
    date,
    totalAmount,
    installmentsCount,
    category,
    goal,
  );
}
