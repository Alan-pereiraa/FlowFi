import '../entities/dashboard_overview.dart';

abstract interface class DashboardRepository {
  Future<DashboardOverview> overview({required DateTime month});
}
