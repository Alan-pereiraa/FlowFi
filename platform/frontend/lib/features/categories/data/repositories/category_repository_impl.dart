import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_input.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/categories_api.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(categoriesApiProvider)),
);

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._api);

  final CategoriesApi _api;

  @override
  Future<List<Category>> list() async {
    final dtos = await guardApi(_api.list);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Category> create(CategoryInput input) async {
    final dto = await guardApi(() => _api.create(input));
    return dto.toEntity();
  }
}
