import '../entities/category.dart';
import '../entities/category_draft.dart';

/// The caller's categories on `/categories`. Throws `Failure`.
/// Categories on `/categories`, scoped to the caller. Throws `Failure`.
abstract interface class CategoryRepository {
  /// Every live category, oldest first (the endpoint is not paginated).
  Future<List<Category>> list();

  Future<Category> show(int id);

  Future<Category> create(CategoryDraft data);

  Future<Category> update(int id, CategoryDraft data);

  Future<void> remove(int id);
}
