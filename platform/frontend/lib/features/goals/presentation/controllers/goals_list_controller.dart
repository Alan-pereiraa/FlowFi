import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/error_messages.dart';
import '../../data/repositories/goal_repository_impl.dart';
import 'goals_list_state.dart';

final goalsListControllerProvider =
    NotifierProvider.autoDispose<GoalsListController, GoalsListState>(
      GoalsListController.new,
    );

class GoalsListController extends Notifier<GoalsListState> {
  @override
  GoalsListState build() {
    Future.microtask(load);
    return const GoalsListState(loading: true);
  }

  Future<void> load() async {
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
        errorMessage: ErrorMessages.general(failure),
      );
    }
  }
}
