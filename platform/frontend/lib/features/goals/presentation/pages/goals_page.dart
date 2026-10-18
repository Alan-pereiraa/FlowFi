import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../shared/widgets/app_add_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../../../shared/widgets/responsive_grid.dart';
import '../controllers/goals_list_controller.dart';
import '../goal_routes.dart';
import '../widgets/goal_card.dart';

/// "Minhas Metas". Lives inside the app shell (top bar + bottom tabs), so it
/// has no `Scaffold` of its own.
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A refresh that fails over data already on screen: say so, keep the data.
    ref.listen(goalsListControllerProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message != null && ref.read(goalsListControllerProvider).loaded) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final state = ref.watch(goalsListControllerProvider);
    final controller = ref.read(goalsListControllerProvider.notifier);
    void create() => context.push(GoalRoutes.create);

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
      body = ResponsiveGrid(
        children: [
          for (final goal in state.goals)
            GoalCard(
              goal: goal,
              onTap: () =>
                  context.push(GoalRoutes.detail(goal.id), extra: goal),
            ),
          AppAddCard(
            title: 'Nova Meta',
            message: 'Defina um novo objetivo para seu futuro financeiro.',
            onTap: create,
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ResponsiveCenter(
          verticalPadding: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onCreate: create),
              const SizedBox(height: 24),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

/// Title and subtitle, with the create button under them on a phone and
/// beside them on a wide screen.
class _Header extends StatelessWidget {
  const _Header({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minhas Metas',
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Acompanhe seus objetivos financeiros e celebre o progresso.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final button = AppButton(
      label: 'Criar Nova Meta',
      icon: Icons.add,
      onPressed: onCreate,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [texts, const SizedBox(height: 20), button],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: texts),
            const SizedBox(width: 24),
            // Tight width: the theme's filled button is otherwise infinitely wide.
            SizedBox(width: 240, child: button),
          ],
        );
      },
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
