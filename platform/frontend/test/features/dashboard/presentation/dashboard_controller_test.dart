import 'package:flowfi_app/core/clock.dart';
import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/features/dashboard/data/models/dashboard_overview_dto.dart';
import 'package:flowfi_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:flowfi_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flowfi_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:flowfi_app/shared/money/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class _MockDashboard extends Mock implements DashboardRepository {}

void main() {
  late _MockDashboard dashboard;
  final now = DateTime(2026, 10, 23, 22, 30);

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    dashboard = _MockDashboard();
    when(() => dashboard.overview(month: any(named: 'month'))).thenAnswer(
      (_) async => DashboardOverviewDto.fromJson(dashboardJson()).toEntity(),
    );
  });

  Future<ProviderContainer> boot() async {
    final container = ProviderContainer.test(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(dashboard),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    container.listen(dashboardControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  test('loads the month summary, newest goals and latest rows', () async {
    final container = await boot();
    final state = container.read(dashboardControllerProvider);

    verify(() => dashboard.overview(month: now)).called(1);
    expect(state.loaded, isTrue);
    expect(state.loading, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.summary?.expense.total, const Money(63030));
    expect(state.recentGoals.map((g) => g.id), [5, 2]);
    expect(state.latestTransactions.map((t) => t.id), [9, 8, 7]);
  });

  test('a failed first load shows the error screen', () async {
    when(() => dashboard.overview(month: any(named: 'month')))
        .thenThrow(const NetworkFailure());

    final container = await boot();
    final state = container.read(dashboardControllerProvider);

    expect(state.showError, isTrue);
    expect(state.errorMessage, contains('Sem conexão'));
  });

  test('a failed refresh keeps the data on screen', () async {
    final container = await boot();
    when(() => dashboard.overview(month: any(named: 'month')))
        .thenThrow(const UnexpectedFailure());

    await container.read(dashboardControllerProvider.notifier).load();
    final state = container.read(dashboardControllerProvider);

    expect(state.showError, isFalse);
    expect(state.loaded, isTrue);
    expect(state.summary, isNotNull);
    expect(state.recentGoals, hasLength(2));
    expect(state.errorMessage, isNotNull);
  });
}
