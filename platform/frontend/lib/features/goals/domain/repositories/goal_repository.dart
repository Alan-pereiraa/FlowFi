import '../entities/goal.dart';
import '../entities/goal_update.dart';
import '../entities/new_goal.dart';

abstract interface class GoalRepository {
  Future<List<Goal>> list();

  Future<Goal> show(int id);

  Future<Goal> create(NewGoal data);

  Future<Goal> update(int id, GoalUpdate data);

  Future<void> remove(int id);

  Future<Goal> deposit(Goal goal, int cents);

  Future<Goal> withdraw(Goal goal, int cents);
}
