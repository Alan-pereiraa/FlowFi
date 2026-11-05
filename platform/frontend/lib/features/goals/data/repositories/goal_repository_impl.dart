import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/utils/date_labels.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_creation.dart';
import '../../domain/entities/goal_update.dart';
import '../../domain/entities/new_goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goals_api.dart';
import '../models/goal_update_dto.dart';
import '../models/new_goal_dto.dart';

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepositoryImpl(ref.watch(goalsApiProvider)),
);

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Description stored on the transfer that carries the initial amount.
  static const initialDepositDescription = 'Valor inicial';

  /// Description stored on a deposit made from the goal screen.
  static const depositDescription = 'Depósito na meta';

  static const withdrawalDescription = 'Resgate da meta';

  final GoalsApi _api;
  final DateTime Function() _clock;

  @override
  Future<List<Goal>> list() async {
    final dtos = await guardApi(_api.listGoals);
    return [for (final dto in dtos) dto.toEntity()];
  }

  @override
  Future<Goal> show(int id) async {
    final dto = await guardApi(() => _api.showGoal(id));
    return dto.toEntity();
  }

  @override
  Future<Goal> update(int id, GoalUpdate data) async {
    final dto = await guardApi(() => _api.updateGoal(id, GoalUpdateDto(data)));
    return dto.toEntity();
  }

  @override
  Future<void> remove(int id) => guardApi(() => _api.deleteGoal(id));

  @override
  Future<Goal> deposit(Goal goal, int cents) async {
    await guardApi(
      () => _api.depositToGoal(
        goalId: goal.id,
        amount: Money.toApi(cents),
        date: DateLabels.toApi(_clock()),
        description: depositDescription,
      ),
    );
    return _refreshed(goal, cents);
  }

  @override
  Future<Goal> withdraw(Goal goal, int cents) async {
    await guardApi(
      () => _api.withdrawFromGoal(
        goalId: goal.id,
        amount: Money.toApi(cents),
        date: DateLabels.toApi(_clock()),
        description: withdrawalDescription,
      ),
    );
    return _refreshed(goal, -cents);
  }

  Future<Goal> _refreshed(Goal goal, int movedCents) async {
    try {
      return await show(goal.id);
    } on UnauthorizedFailure {
      rethrow;
    } on Failure {
      return goal.copyWith(currentCents: goal.currentCents + movedCents);
    }
  }

  @override
  Future<GoalCreation> create(NewGoal data) async {
    final dto = await guardApi(() => _api.createGoal(NewGoalDto(data)));
    final goal = dto.toEntity();

    if (data.initialCents <= 0) return GoalCreation(goal: goal);

    try {
      await guardApi(
        () => _api.depositToGoal(
          goalId: goal.id,
          amount: Money.toApi(data.initialCents),
          date: DateLabels.toApi(_clock()),
          description: initialDepositDescription,
        ),
      );
    } on UnauthorizedFailure {
      // The session is over: let the app handle it like any other call.
      rethrow;
    } on Failure {
      // The goal already exists, so don't report the whole creation as failed.
      return GoalCreation(
        goal: goal,
        initialCents: data.initialCents,
        initialDepositFailed: true,
      );
    }

    return GoalCreation(
      goal: goal.copyWith(currentCents: goal.currentCents + data.initialCents),
      initialCents: data.initialCents,
    );
  }
}
