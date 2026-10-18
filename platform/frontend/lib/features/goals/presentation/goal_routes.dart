import '../../../app/routes.dart';

/// Goal sub-route paths. Kept apart from `goals_route.dart` so pages can
/// navigate without importing the pages that the route definition imports.
/// They hang off the existing `Routes.goals` path so they render inside the
/// app shell, like the design shows (top bar + tabs).
abstract final class GoalRoutes {
  static const create = '${Routes.goals}/new';
  static const success = '${Routes.goals}/success';

  static String detail(int id) => '${Routes.goals}/$id';
}
