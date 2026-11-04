import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../../../shared/widgets/responsive_grid.dart';
import '../category_routes.dart';
import '../controllers/categories_list_controller.dart';
import '../widgets/category_card.dart';

/// "Categorias": every category with its limit, the entry point to add, edit
/// and remove them. A tab of the app shell (top bar + bottom tabs), so it has
/// no `Scaffold` of its own.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A refresh that fails over data already on screen: say so, keep the data.
    ref.listen(categoriesListControllerProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message != null &&
          ref.read(categoriesListControllerProvider).loaded) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final state = ref.watch(categoriesListControllerProvider);
    final controller = ref.read(categoriesListControllerProvider.notifier);
    final theme = Theme.of(context);
    void create() => context.push(CategoryRoutes.create);

    final Widget body;
    if (state.showSpinner) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.showError) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 240,
              child: OutlinedButton(
                onPressed: controller.load,
                child: const Text('Tentar novamente'),
              ),
            ),
          ],
        ),
      );
    } else if (state.categories.isEmpty) {
      body = const EmptyState(
        icon: Icons.category_outlined,
        title: 'Nenhuma categoria ainda',
        message: 'Organize seus gastos e defina um limite mensal.',
      );
    } else {
      body = ResponsiveGrid(
        minTileWidth: 340,
        children: [
          for (final category in state.categories)
            CategoryCard(
              category: category,
              spentCents: state.spentOf(category.id),
              onEdit: () => context.push(
                CategoryRoutes.edit(category.id),
                extra: category,
              ),
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
          'Categorias',
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Organize seus gastos e defina limites mensais.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final button = AppButton(
      label: 'Nova Categoria',
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
