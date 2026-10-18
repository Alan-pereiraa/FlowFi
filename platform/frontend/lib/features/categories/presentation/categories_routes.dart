import 'package:go_router/go_router.dart';

import '../domain/entities/category.dart';
import 'category_routes.dart';
import 'pages/categories_page.dart';
import 'pages/category_form_page.dart';

/// The "Categorias" tab. It goes in a `StatefulShellBranch` of the app shell
/// (`router.dart`), so it keeps the top bar and the bottom tabs:
///
///     StatefulShellBranch(routes: [categoriesRoute()]),
GoRoute categoriesRoute() => GoRoute(
  path: CategoryRoutes.list,
  builder: (_, _) => const CategoriesPage(),
);

/// Add and edit are full screens (own app bar, no bottom tabs), like the
/// prototypes. They go in the top-level `routes:` list in `router.dart`:
///
///     ...categoryFormRoutes(),
List<GoRoute> categoryFormRoutes() => [
  // Declared before `:id/edit` so "new" is never read as an id.
  GoRoute(
    path: CategoryRoutes.create,
    builder: (_, _) => const CategoryFormPage.create(),
  ),
  GoRoute(
    path: '/categories/:id/edit',
    // A path that is not a number is a dead end: go back to the list.
    redirect: (_, state) =>
        int.tryParse(state.pathParameters['id'] ?? '') == null
        ? CategoryRoutes.list
        : null,
    builder: (_, state) => CategoryFormPage.edit(
      categoryId: int.parse(state.pathParameters['id']!),
      // Handed over by the list; null after a browser refresh, then fetched.
      initial: state.extra is Category ? state.extra! as Category : null,
    ),
  ),
];
