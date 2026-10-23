import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../core/clock.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../../../shared/widgets/responsive_grid.dart';
import '../../../goals/presentation/goal_routes.dart';
import '../../../identity/presentation/controllers/session_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_state.dart';
import '../widgets/dashboard_section_card.dart';
import '../widgets/flow_total_card.dart';
import '../widgets/latest_transaction_row.dart';
import '../widgets/month_summary_card.dart';
import '../widgets/recent_goal_row.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(dashboardControllerProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message != null && ref.read(dashboardControllerProvider).loaded) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);
    final firstName = ref.watch(
      sessionControllerProvider.select((s) => s.user?.firstName),
    );

    Future<void> newTransaction() async {
      final changed = await context.push<bool>(Routes.dashboardNewTransaction);
      if (changed == true) await controller.load();
    }

    final Widget body;
    if (state.showSpinner) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.showError) {
      body = _ErrorPanel(
        message: state.errorMessage!,
        onRetry: controller.load,
      );
    } else {
      body = _Sections(state: state, today: ref.watch(clockProvider)());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova transação',
        onPressed: newTransaction,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveCenter(
            verticalPadding: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Greeting(firstName: firstName),
                const SizedBox(height: 24),
                body,
                const SizedBox(height: 72),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String? firstName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = firstName?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Olá!' : 'Olá, $name',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Aqui está o resumo das suas finanças hoje.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({required this.state, required this.today});

  final DashboardState state;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null) ...[
          MonthSummaryCard(summary: summary),
          const SizedBox(height: 16),
          ResponsiveGrid(
            maxColumns: 2,
            minTileWidth: 240,
            children: [
              FlowTotalCard.income(amount: summary.income.total),
              FlowTotalCard.expense(amount: summary.expense.total),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _lists(context),
      ],
    );
  }

  Widget _lists(BuildContext context) {
    return ResponsiveGrid(
      maxColumns: 2,
      minTileWidth: 360,
      children: [
        DashboardSectionCard(
          title: 'Metas Recentes',
          onSeeAll: () => context.go(Routes.goals),
          emptyMessage: 'Você ainda não tem metas.',
          children: [
            for (final goal in state.recentGoals)
              RecentGoalRow(
                goal: goal,
                onTap: () =>
                    context.go(GoalRoutes.detail(goal.id), extra: goal),
              ),
          ],
        ),
        DashboardSectionCard(
          title: 'Últimas Transações',
          onSeeAll: () => context.go(Routes.transactions),
          emptyMessage: 'Nenhuma transação registrada.',
          children: [
            for (final item in state.latestTransactions)
              LatestTransactionRow(transaction: item, today: today),
          ],
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 240,
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}
