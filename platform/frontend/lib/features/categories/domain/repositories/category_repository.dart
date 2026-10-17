import '../entities/category.dart';
import '../entities/category_draft.dart';

/// Categories on `/categories`, scoped to the caller. Throws `Failure`.
abstract interface class CategoryRepository {
  Future<List<Category>> list();

  Future<Category> show(int id);

  Future<Category> create(CategoryDraft data);

  Future<Category> update(int id, CategoryDraft data);

  Future<void> remove(int id);
}
