import 'package:flutter/foundation.dart' show immutable;

import '../../../goals/domain/entities/goal.dart';
import '../../domain/entities/month_summary.dart';
import '../../domain/entities/recent_transaction.dart';

@immutable
class DashboardState {
  const DashboardState({
    this.loading = false,
    this.loaded = false,
    this.summary,
    this.recentGoals = const [],
    this.latestTransactions = const [],
    this.errorMessage,
  });

  final bool loading;
  final bool loaded;
  final MonthSummary? summary;
  final List<Goal> recentGoals;
  final List<RecentTransaction> latestTransactions;
  final String? errorMessage;

  bool get showSpinner => loading && !loaded;

  bool get showError => !loaded && !loading && errorMessage != null;
}
