import '../entities/goal.dart';
import '../entities/goal_creation.dart';
import '../entities/goal_update.dart';
import '../entities/new_goal.dart';

/// Goals on `/goals`, scoped to the caller. Throws `Failure`.
abstract interface class GoalRepository {
  Future<List<Goal>> list();

  Future<Goal> show(int id);

  /// Creates the goal and, when [NewGoal.initialCents] is set, registers it as
  /// a first deposit. A failed deposit does not fail the call: the goal is
  /// kept and [GoalCreation.initialDepositFailed] is set.
  Future<GoalCreation> create(NewGoal data);

  Future<Goal> update(int id, GoalUpdate data);

  /// The API refuses (422) to delete a goal that already has deposits.
  Future<void> remove(int id);

  /// Adds [cents] to [goal] and returns it with the new balance. The money
  /// moves in one call; the refresh that follows is best effort, so a failed
  /// refresh still returns the goal with the amount added.
  Future<Goal> deposit(Goal goal, int cents);
}
