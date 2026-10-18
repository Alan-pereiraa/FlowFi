/// Category route paths. Kept apart from `categories_routes.dart` so pages can
/// navigate without importing the pages that the route definitions import.
// Not added to the shared `Routes` class on purpose: that file is not touched.
abstract final class CategoryRoutes {
  static const list = '/categories';
  static const create = '/categories/new';

  static String edit(int id) => '/categories/$id/edit';
}
