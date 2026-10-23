import '../../../../shared/money/money.dart';
import '../../domain/entities/money_flow.dart';
import '../../domain/entities/month_summary.dart';

class SummaryDto {
  const SummaryDto({
    required this.month,
    required this.income,
    required this.expense,
    required this.projectedBalance,
  });

  factory SummaryDto.fromJson(Map<String, dynamic> json) => SummaryDto(
    month: (json['period'] as Map<String, dynamic>)['month'] as String,
    income: _flow(json['income']),
    expense: _flow(json['expense']),
    projectedBalance: json['projected_balance'].toString(),
  );

  final String month;
  final Map<String, String> income;
  final Map<String, String> expense;
  final String projectedBalance;

  MonthSummary toEntity() {
    final parts = month.split('-').map(int.parse).toList();
    return MonthSummary(
      month: DateTime(parts[0], parts[1]),
      income: _toFlow(income),
      expense: _toFlow(expense),
      projectedBalance: Money.parse(projectedBalance),
    );
  }

  static Map<String, String> _flow(Object? json) {
    final map = json as Map<String, dynamic>;
    return {
      for (final key in const ['paid', 'pending', 'total'])
        key: map[key].toString(),
    };
  }

  static MoneyFlow _toFlow(Map<String, String> flow) => MoneyFlow(
    paid: Money.parse(flow['paid']!),
    pending: Money.parse(flow['pending']!),
    total: Money.parse(flow['total']!),
  );
}
