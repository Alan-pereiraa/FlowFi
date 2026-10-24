import 'package:flowfi_app/features/dashboard/data/models/dashboard_overview_dto.dart';
import 'package:flowfi_app/features/dashboard/domain/entities/money_flow.dart';
import 'package:flowfi_app/features/dashboard/domain/entities/month_summary.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flowfi_app/shared/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

MonthSummary _summary({required int income, required int expense}) =>
    MonthSummary(
      month: DateTime(2026, 10),
      income: MoneyFlow(
        paid: Money.zero,
        pending: Money.zero,
        total: Money(income),
      ),
      expense: MoneyFlow(
        paid: Money.zero,
        pending: Money.zero,
        total: Money(expense),
      ),
      projectedBalance: Money(income - expense),
    );

void main() {
  test('parses the summary as cents, negatives included', () {
    final overview = DashboardOverviewDto.fromJson(
      dashboardJson(projectedBalance: '-75.25'),
    ).toEntity();
    final summary = overview.summary;

    expect(summary.month, DateTime(2026, 9));
    expect(summary.income.total, const Money(480000));
    expect(summary.income.paid, const Money(450000));
    expect(summary.expense.total, const Money(63030));
    expect(summary.expense.pending, const Money(14990));
    expect(summary.projectedBalance, const Money(-7525));
  });

  test('parses recent transactions with category or goal', () {
    final rows = DashboardOverviewDto.fromJson(dashboardJson())
        .toEntity()
        .recentTransactions;

    expect(rows.map((r) => r.id), [9, 8, 7, 6, 5]);
    final transfer = rows[2];
    expect(transfer.type, TransactionType.transfer);
    expect(transfer.category, isNull);
    expect(transfer.goal?.name, 'Trip to Japan');
    expect(transfer.date, DateTime(2026, 9, 14));
    expect(transfer.totalAmount, const Money(25000));
    expect(rows.first.category?.color, '#2196F3');
  });

  test('maps goal progress to goals', () {
    final goal = DashboardOverviewDto.fromJson(
      dashboardJson(goals: [goalProgressJson()]),
    ).toEntity().goals.single;

    expect(goal.targetCents, 1000000);
    expect(goal.currentCents, 250000);
    expect(goal.percent, 25);
    expect(goal.expiresAt, DateTime(2027, 3));
  });

  group('incomeUsedPercent', () {
    test('rounds down', () {
      expect(_summary(income: 80000, expense: 42550).incomeUsedPercent, 53);
    });

    test('can pass 100', () {
      expect(_summary(income: 10000, expense: 11250).incomeUsedPercent, 112);
    });

    test('is null without income', () {
      expect(_summary(income: 0, expense: 5000).incomeUsedPercent, isNull);
    });
  });
}
