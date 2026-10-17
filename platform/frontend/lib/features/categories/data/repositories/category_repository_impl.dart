import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_draft.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/categories_api.dart';
import '../models/category_draft_dto.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(categoriesApiProvider)),
);

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._api);

  final CategoriesApi _api;

  @override
  Future<List<Category>> list() async {
    final dtos = await guardApi(_api.listCategories);
    return [for (final dto in dtos) dto.toEntity()];
  }

  @override
  Future<Category> show(int id) async {
    final dto = await guardApi(() => _api.showCategory(id));
    return dto.toEntity();
  }

  @override
  Future<Category> create(CategoryDraft data) async {
    final dto = await guardApi(
      () => _api.createCategory(CategoryDraftDto(data)),
    );
    return dto.toEntity();
  }

  @override
  Future<Category> update(int id, CategoryDraft data) async {
    final dto = await guardApi(
      () => _api.updateCategory(id, CategoryDraftDto(data)),
    );
    return dto.toEntity();
  }

  @override
  Future<void> remove(int id) => guardApi(() => _api.deleteCategory(id));
}
