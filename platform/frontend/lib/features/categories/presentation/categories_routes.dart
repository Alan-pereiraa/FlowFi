import 'package:go_router/go_router.dart';

import '../domain/entities/category.dart';
import 'category_routes.dart';
import 'pages/categories_page.dart';
import 'pages/category_form_page.dart';

GoRoute categoriesRoute() => GoRoute(
  path: CategoryRoutes.list,
  builder: (_, _) => const CategoriesPage(),
);

List<GoRoute> categoryFormRoutes() => [
  GoRoute(
    path: CategoryRoutes.create,
    builder: (_, _) => const CategoryFormPage.create(),
  ),
  GoRoute(
    path: '/categories/:id/edit',
    redirect: (_, state) =>
        int.tryParse(state.pathParameters['id'] ?? '') == null
        ? CategoryRoutes.list
        : null,
    builder: (_, state) => CategoryFormPage.edit(
      categoryId: int.parse(state.pathParameters['id']!),
      initial: state.extra is Category ? state.extra! as Category : null,
    ),
  ),
];
