import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_api.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(dashboardApiProvider)),
);

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._api);

  final DashboardApi _api;

  @override
  Future<DashboardOverview> overview({required DateTime month}) async {
    final query = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final dto = await guardApi(() => _api.overview(month: query));
    return dto.toEntity();
  }
}
