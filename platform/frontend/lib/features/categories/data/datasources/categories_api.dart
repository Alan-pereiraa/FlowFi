import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/category_input.dart';
import '../models/category_dto.dart';

final categoriesApiProvider = Provider<CategoriesApi>(
  (ref) => CategoriesApi(ref.watch(apiClientProvider)),
);

/// One method per Category endpoint. Throws [ApiException].
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

  Future<CategoryDto> create(CategoryInput input) async {
    final response = await _send(
      () => _dio.post<Map<String, dynamic>>(
        '/categories',
        data: CategoryDto.inputToJson(input),
      ),
    );
    return CategoryDto.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
