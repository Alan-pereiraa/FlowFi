import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../domain/entities/goal.dart';
import 'pages/goal_created_page.dart';
import 'pages/goal_detail_page.dart';
import 'pages/goal_form_page.dart';
import 'pages/goals_page.dart';

GoRoute goalsRoute() => GoRoute(
  path: Routes.goals,
  builder: (_, _) => const GoalsPage(),
  routes: [
    GoRoute(path: 'new', builder: (_, _) => const GoalFormPage()),
    GoRoute(
      path: 'success',
      redirect: (_, state) => state.extra is Goal ? null : Routes.goals,
      builder: (_, state) => GoalCreatedPage(goal: state.extra! as Goal),
    ),
    GoRoute(
      path: ':id',
      redirect: (_, state) =>
          int.tryParse(state.pathParameters['id'] ?? '') == null
          ? Routes.goals
          : null,
      builder: (_, state) => GoalDetailPage(
        goalId: int.parse(state.pathParameters['id']!),
        initial: state.extra is Goal ? state.extra! as Goal : null,
      ),
    ),
  ],
);
