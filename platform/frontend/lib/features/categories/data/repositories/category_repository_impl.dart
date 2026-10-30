import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/utils/money.dart' as cents;
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

  Future<List<Category>> listCategories() async {
    final dtos = await guardApi(_api.list);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Map<int, int>> spentInMonth(DateTime month) async {
    final key =
        '${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}';
    final totals = await guardApi(() => _api.spendingByCategory(key));
    return {
      for (final entry in totals.entries)
        entry.key: cents.Money.parseApi(entry.value) ?? 0,
    };
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
