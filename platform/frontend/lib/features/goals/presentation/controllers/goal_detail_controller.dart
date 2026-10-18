import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/errors/ledger_error_messages.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_update.dart';
import 'goal_detail_state.dart';
import 'goals_list_controller.dart';

final goalDetailControllerProvider =
    NotifierProvider.autoDispose<GoalDetailController, GoalDetailState>(
      GoalDetailController.new,
    );

/// One goal: fetch it, edit it, add money to it, delete it.
class GoalDetailController extends Notifier<GoalDetailState> {
  static const _fields = [
    'name',
    'icon',
    'color',
    'target_amount',
    'expires_at',
  ];

  @override
  GoalDetailState build() => const GoalDetailState();

  /// Fetches the goal when the screen was opened by id alone and nothing was
  /// handed over.
  Future<void> load(int id) async {
    state = state.copyWith(loadingInitial: true, loadError: () => null);
    try {
      final goal = await ref.read(goalRepositoryProvider).show(id);
      if (!ref.mounted) return;
      state = state.copyWith(loadingInitial: false, goal: goal);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        loadingInitial: false,
        loadError: () => LedgerErrorMessages.general(failure),
      );
    }
  }

  Future<void> save(int id, GoalUpdate data) async {
    if (state.busy) return;
    state = state.copyWith(
      saving: true,
      fieldErrors: const {},
      formError: () => null,
    );
    try {
      final goal = await ref.read(goalRepositoryProvider).update(id, data);
      if (!ref.mounted) return;
      state = state.copyWith(
        saving: false,
        goal: goal,
        outcome: () => GoalOutcome.updated,
      );
      // The list behind this screen is now stale.
      ref.invalidate(goalsListControllerProvider);
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return;
      final fieldErrors = {
        for (final field in _fields)
          field: ?LedgerErrorMessages.goalField(failure, field),
      };
      state = state.copyWith(
        saving: false,
        fieldErrors: fieldErrors,
        formError: () => fieldErrors.isEmpty
            ? LedgerErrorMessages.general(failure)
            : null,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        saving: false,
        formError: () => LedgerErrorMessages.general(failure),
      );
    }
  }

  /// Adds [cents] to [goal]. The screen stays open and shows the new balance.
  Future<void> deposit(Goal goal, int cents) async {
    if (state.busy) return;
    state = state.copyWith(depositing: true, depositError: () => null);
    try {
      final updated = await ref
          .read(goalRepositoryProvider)
          .deposit(state.goal ?? goal, cents);
      if (!ref.mounted) return;
      state = state.copyWith(
        depositing: false,
        goal: updated,
        depositCount: state.depositCount + 1,
      );
      ref.invalidate(goalsListControllerProvider);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        depositing: false,
        depositError: () => LedgerErrorMessages.goalDeposit(failure),
      );
    }
  }

  Future<void> remove(int id) async {
    if (state.busy) return;
    state = state.copyWith(removing: true, formError: () => null);
    try {
      await ref.read(goalRepositoryProvider).remove(id);
      if (!ref.mounted) return;
      state = state.copyWith(
        removing: false,
        outcome: () => GoalOutcome.removed,
      );
      ref.invalidate(goalsListControllerProvider);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        removing: false,
        formError: () => LedgerErrorMessages.goalDelete(failure),
      );
    }
  }
}
