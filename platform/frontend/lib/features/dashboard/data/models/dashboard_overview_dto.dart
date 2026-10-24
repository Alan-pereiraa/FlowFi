import '../../domain/entities/dashboard_overview.dart';
import 'goal_progress_dto.dart';
import 'recent_transaction_dto.dart';
import 'summary_dto.dart';

class DashboardOverviewDto {
  const DashboardOverviewDto({
    required this.summary,
    required this.recentTransactions,
    required this.goals,
  });

  factory DashboardOverviewDto.fromJson(Map<String, dynamic> json) =>
      DashboardOverviewDto(
        summary: SummaryDto.fromJson(json['summary'] as Map<String, dynamic>),
        recentTransactions: [
          for (final item in json['recent_transactions'] as List<dynamic>)
            RecentTransactionDto.fromJson(item as Map<String, dynamic>),
        ],
        goals: [
          for (final item in json['goals'] as List<dynamic>)
            GoalProgressDto.fromJson(item as Map<String, dynamic>),
        ],
      );

  final SummaryDto summary;
  final List<RecentTransactionDto> recentTransactions;
  final List<GoalProgressDto> goals;

  DashboardOverview toEntity() => DashboardOverview(
    summary: summary.toEntity(),
    recentTransactions: [for (final dto in recentTransactions) dto.toEntity()],
    goals: [for (final dto in goals) dto.toEntity()],
  );
}
