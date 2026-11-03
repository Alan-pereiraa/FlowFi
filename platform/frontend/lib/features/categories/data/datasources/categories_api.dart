import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/category_draft_dto.dart';
import '../models/category_dto.dart';

final categoriesApiProvider = Provider<CategoriesApi>(
  (ref) => CategoriesApi(ref.watch(apiClientProvider)),
);

class CategoriesApi {
  CategoriesApi(this._dio);

  final Dio _dio;

  Future<List<CategoryDto>> list() async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>('/categories'),
    );
    return (response.data!['data'] as List<dynamic>)
        .map((item) => CategoryDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryDto>> listCategories() async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>('/categories'),
    );
    final items = response.data!['data'] as List<dynamic>;
    return [
      for (final item in items)
        CategoryDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<CategoryDto> showCategory(int id) async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>('/categories/$id'),
    );
    return _unwrap(response.data!);
  }

  Future<CategoryDto> createCategory(CategoryDraftDto body) async {
    final response = await _send(
      () => _dio.post<Map<String, dynamic>>('/categories', data: body.toJson()),
    );
    return _unwrap(response.data!);
  }

  Future<CategoryDto> updateCategory(int id, CategoryDraftDto body) async {
    final response = await _send(
      () => _dio.patch<Map<String, dynamic>>(
        '/categories/$id',
        data: body.toJson(),
      ),
    );
    return _unwrap(response.data!);
  }

  Future<void> deleteCategory(int id) =>
      _send(() => _dio.delete<void>('/categories/$id'));

  /// Spending of [month] (`YYYY-MM`) per category id, as the API's decimal
  /// `total` string (paid + pending, the same sum the limit check uses).
  /// Categories with no expense that month are absent.
  Future<Map<int, String>> spendingByCategory(String month) async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>(
        '/dashboard/spending-by-category',
        queryParameters: {'month': month},
      ),
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final rows = (data['categories'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final totals = <int, String>{};
    for (final row in rows) {
      final category = row['category'] as Map<String, dynamic>;
      totals[category['id'] as int] = row['total'].toString();
    }
    return totals;
  }

  /// Single-resource responses wrap the object in `{ "data": {...} }`.
  CategoryDto _unwrap(Map<String, dynamic> body) =>
      CategoryDto.fromJson(body['data'] as Map<String, dynamic>);

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
