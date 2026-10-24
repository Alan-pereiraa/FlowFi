import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/dashboard_overview_dto.dart';

final dashboardApiProvider = Provider<DashboardApi>(
  (ref) => DashboardApi(ref.watch(apiClientProvider)),
);

class DashboardApi {
  DashboardApi(this._dio);

  final Dio _dio;

  Future<DashboardOverviewDto> overview({required String month}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/dashboard',
        queryParameters: {'month': month},
      );
      return DashboardOverviewDto.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
