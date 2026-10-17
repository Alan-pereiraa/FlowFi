import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/errors/ledger_error_messages.dart';
import '../../data/repositories/goal_repository_impl.dart';
import 'goals_list_state.dart';

final goalsListControllerProvider =
    NotifierProvider.autoDispose<GoalsListController, GoalsListState>(
      GoalsListController.new,
    );

/// Loads the caller's goals; also used for pull-to-refresh and "retry".
class GoalsListController extends Notifier<GoalsListState> {
  @override
  GoalsListState build() {
    Future.microtask(load);
    return const GoalsListState(loading: true);
  }

  Future<void> load() async {
    // Keep what is already on screen while a refresh is in flight.
    state = GoalsListState(
      loading: true,
      loaded: state.loaded,
      goals: state.goals,
    );
    try {
      final goals = await ref.read(goalRepositoryProvider).list();
      if (!ref.mounted) return;
      state = GoalsListState(loaded: true, goals: goals);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = GoalsListState(
        loaded: state.loaded,
        goals: state.goals,
        errorMessage: LedgerErrorMessages.general(failure),
      );
    }
  }
}
