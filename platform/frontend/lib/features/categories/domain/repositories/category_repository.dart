import '../entities/category.dart';
import '../entities/category_draft.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> list();

  Future<Map<int, int>> spentInMonth(DateTime month);

  Future<Category> show(int id);

  Future<Category> create(CategoryDraft data);

  Future<Category> update(int id, CategoryDraft data);

  Future<void> remove(int id);
}
