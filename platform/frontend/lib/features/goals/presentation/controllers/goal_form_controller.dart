import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/errors/ledger_error_messages.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/new_goal.dart';
import 'goal_form_state.dart';
import 'goals_list_controller.dart';

final goalFormControllerProvider =
    NotifierProvider.autoDispose<GoalFormController, GoalFormState>(
      GoalFormController.new,
    );

class GoalFormController extends Notifier<GoalFormState> {
  static const _fields = [
    'name',
    'icon',
    'color',
    'target_amount',
    'expires_at',
  ];

  @override
  GoalFormState build() => const GoalFormState();

  Future<void> create(NewGoal data) async {
    if (state.saving) return;

    state = const GoalFormState(saving: true);
    try {
      final created = await ref.read(goalRepositoryProvider).create(data);
      if (!ref.mounted) return;
      state = GoalFormState(created: created);
      // The list behind this form is now stale.
      ref.invalidate(goalsListControllerProvider);
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return;
      final fieldErrors = {
        for (final field in _fields)
          field: ?LedgerErrorMessages.goalField(failure, field),
      };
      state = GoalFormState(
        fieldErrors: fieldErrors,
        formError: fieldErrors.isEmpty
            ? LedgerErrorMessages.general(failure)
            : null,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = GoalFormState(formError: LedgerErrorMessages.general(failure));
    }
  }
}
