import 'package:flutter/foundation.dart';

import '../../../goals/domain/entities/goal.dart';
import 'month_summary.dart';
import 'recent_transaction.dart';

@immutable
class DashboardOverview {
  const DashboardOverview({
    required this.summary,
    required this.recentTransactions,
    required this.goals,
  });

  final MonthSummary summary;
  final List<RecentTransaction> recentTransactions;
  final List<Goal> goals;

  @override
  bool operator ==(Object other) =>
      other is DashboardOverview &&
      other.summary == summary &&
      listEquals(other.recentTransactions, recentTransactions) &&
      listEquals(other.goals, goals);

  @override
  int get hashCode => Object.hash(
    summary,
    Object.hashAll(recentTransactions),
    Object.hashAll(goals),
  );
}
