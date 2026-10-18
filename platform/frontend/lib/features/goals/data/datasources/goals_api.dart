import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/goal_dto.dart';
import '../models/goal_update_dto.dart';
import '../models/new_goal_dto.dart';

final goalsApiProvider = Provider<GoalsApi>(
  (ref) => GoalsApi(ref.watch(apiClientProvider)),
);

/// One method per endpoint used by the goals screens. Throws [ApiException].
class GoalsApi {
  GoalsApi(this._dio);

  final Dio _dio;

  Future<List<GoalDto>> listGoals() async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>('/goals'),
    );
    final items = response.data!['data'] as List<dynamic>;
    return [
      for (final item in items) GoalDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<GoalDto> showGoal(int id) async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>('/goals/$id'),
    );
    return GoalDto.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<GoalDto> updateGoal(int id, GoalUpdateDto body) async {
    final response = await _send(
      () => _dio.patch<Map<String, dynamic>>('/goals/$id', data: body.toJson()),
    );
    return GoalDto.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteGoal(int id) =>
      _send(() => _dio.delete<void>('/goals/$id'));

  Future<GoalDto> createGoal(NewGoalDto body) async {
    final response = await _send(
      () => _dio.post<Map<String, dynamic>>('/goals', data: body.toJson()),
    );
    return GoalDto.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Puts money into a goal: a `transfer` transaction, which is how the
  /// backend credits `current_amount`. [amount] is a decimal string and
  /// [date] is `yyyy-MM-dd`.
  Future<void> depositToGoal({
    required int goalId,
    required String amount,
    required String date,
    required String description,
  }) => _send(
    () => _dio.post<Map<String, dynamic>>(
      '/transactions',
      data: {
        'type': 'transfer',
        'goal_id': goalId,
        'total_amount': amount,
        'date': date,
        'description': description,
      },
    ),
  );

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
