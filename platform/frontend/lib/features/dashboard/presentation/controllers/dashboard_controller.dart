import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clock.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import 'dashboard_state.dart';

final dashboardControllerProvider =
    NotifierProvider.autoDispose<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardState> {
  static const recentGoalsCount = 2;
  static const latestTransactionsCount = 3;

  int _generation = 0;

  @override
  DashboardState build() {
    Future.microtask(load);
    return const DashboardState(loading: true);
  }

  Future<void> load() async {
    final generation = ++_generation;
    state = _copy(loading: true, errorMessage: null);
    try {
      final overview = await ref
          .read(dashboardRepositoryProvider)
          .overview(month: ref.read(clockProvider)());
      if (!ref.mounted || generation != _generation) return;
      final newestGoals = [...overview.goals]
        ..sort((a, b) => b.id.compareTo(a.id));
      state = DashboardState(
        loaded: true,
        summary: overview.summary,
        recentGoals: newestGoals.take(recentGoalsCount).toList(),
        latestTransactions: overview.recentTransactions
            .take(latestTransactionsCount)
            .toList(),
      );
    } on Failure catch (failure) {
      if (!ref.mounted || generation != _generation) return;
      state = _copy(
        loading: false,
        errorMessage: ErrorMessages.general(failure),
      );
    }
  }

  DashboardState _copy({required bool loading, String? errorMessage}) =>
      DashboardState(
        loading: loading,
        loaded: state.loaded,
        summary: state.summary,
        recentGoals: state.recentGoals,
        latestTransactions: state.latestTransactions,
        errorMessage: errorMessage,
      );
}
