import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../domain/entities/goal.dart';
import '../domain/entities/goal_creation.dart';
import 'pages/goal_created_page.dart';
import 'pages/goal_detail_page.dart';
import 'pages/goal_form_page.dart';
import 'pages/goals_page.dart';

/// The whole "Metas" branch route: the list, create, success and one goal.
/// Replaces the "Em breve" placeholder for `Routes.goals` in `router.dart`:
///
///     StatefulShellBranch(routes: [goalsRoute()]),
GoRoute goalsRoute() => GoRoute(
  path: Routes.goals,
  builder: (_, _) => const GoalsPage(),
  routes: [
    GoRoute(path: 'new', builder: (_, _) => const GoalFormPage()),
    GoRoute(
      path: 'success',
      // The created goal travels in `extra`, which a web refresh drops:
      // fall back to the list instead of a broken page.
      redirect: (_, state) => state.extra is GoalCreation ? null : Routes.goals,
      builder: (_, state) =>
          GoalCreatedPage(creation: state.extra! as GoalCreation),
    ),
    // After 'new' and 'success', so those words are never read as an id.
    GoRoute(
      path: ':id',
      // A path that is not a number is a dead end: back to the list.
      redirect: (_, state) =>
          int.tryParse(state.pathParameters['id'] ?? '') == null
          ? Routes.goals
          : null,
      builder: (_, state) => GoalDetailPage(
        goalId: int.parse(state.pathParameters['id']!),
        // Handed over by the list; null after a browser refresh, then fetched.
        initial: state.extra is Goal ? state.extra! as Goal : null,
      ),
    ),
  ],
);
