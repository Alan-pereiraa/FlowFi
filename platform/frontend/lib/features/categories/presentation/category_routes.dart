abstract final class CategoryRoutes {
  static const list = '/categories';
  static const create = '/categories/new';

  static String edit(int id) => '/categories/$id/edit';
}
