import '../entities/category.dart';
import '../entities/category_input.dart';

/// The caller's categories on `/categories`. Throws `Failure`.
abstract interface class CategoryRepository {
  /// Every live category, oldest first (the endpoint is not paginated).
  Future<List<Category>> list();

  Future<Category> create(CategoryInput input);
}
