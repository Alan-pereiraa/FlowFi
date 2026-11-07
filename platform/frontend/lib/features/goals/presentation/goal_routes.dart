import '../../../app/routes.dart';

abstract final class GoalRoutes {
  static const create = '${Routes.goals}/new';
  static const success = '${Routes.goals}/success';

  static String detail(int id) => '${Routes.goals}/$id';
}
