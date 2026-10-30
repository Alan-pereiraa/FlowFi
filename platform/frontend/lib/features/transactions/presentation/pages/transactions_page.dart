import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../core/clock.dart';
import '../../../../shared/utils/dates.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/transaction_type.dart';
import '../controllers/transaction_list_controller.dart';
import '../controllers/transaction_list_state.dart';
import '../widgets/transaction_tile.dart';

/// "Transações" tab: the statement grouped by day, with search and filter
/// chips.
// GAP: the design's "Todas as Contas" chip has no backend support (there are
// no accounts), so it filters by category instead. Search runs on the client
// over the rows already loaded (the API has no text search).
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {
      _search.clear();
      ref.read(transactionListControllerProvider.notifier).setSearch('');
    }
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) {
      ref.read(transactionListControllerProvider.notifier).loadMore();
    }
  }

  /// Forms pop with `true` when something changed.
  Future<void> _openForm(String location) async {
    final changed = await context.push<bool>(location);
    if (changed == true) {
      await ref.read(transactionListControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova transação',
        onPressed: () => _openForm(Routes.newTransaction),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: ref.read(transactionListControllerProvider.notifier).refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transações',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: _searching ? 'Fechar busca' : 'Buscar',
                      onPressed: _toggleSearch,
                      icon: Icon(_searching ? Icons.close : Icons.search),
                    ),
                  ],
                ),
              ),
            ),
            if (_searching)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _search,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: ref
                        .read(transactionListControllerProvider.notifier)
                        .setSearch,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por descrição ou categoria',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _FilterChips(state: state)),
            ..._body(context, state),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, TransactionListState state) {
    if (state.loading && state.items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state.error != null && state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmptyState(
                icon: Icons.cloud_off,
                title: 'Não foi possível carregar',
                message: state.error,
              ),
              TextButton(
                onPressed: ref
                    .read(transactionListControllerProvider.notifier)
                    .refresh,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Nenhuma transação',
            message: 'Toque em + para registrar a primeira.',
          ),
        ),
      ];
    }
    if (state.visibleItems.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: 'Nada encontrado',
            message: 'Nenhuma transação carregada combina com a busca.',
          ),
        ),
      ];
    }

    final today = ref.read(clockProvider)();
    return [
      for (final (day, items) in state.byDay)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          sliver: SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _capitalizeMonth(Dates.dayHeader(day, today: today)),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransactionTile(
                    transaction: item,
                    category: state.categories[item.categoryId],
                    onTap: () => _openForm(Routes.editTransaction(item.id)),
                  ),
                ),
            ],
          ),
        ),
      if (state.loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }

  /// "24 de outubro" -> "24 de Outubro", as in the design.
  static String _capitalizeMonth(String header) => header.replaceAllMapped(
    RegExp(r'de ([a-zç])'),
    (m) => 'de ${m[1]!.toUpperCase()}',
  );
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.state});

  final TransactionListState state;

  static const _typeLabels = {
    null: 'Todos os Tipos',
    TransactionType.expense: 'Saídas',
    TransactionType.income: 'Entradas',
    TransactionType.transfer: 'Transferências',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(transactionListControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      IconData? trailing,
    }) {
      return FilterChip(
        showCheckmark: false,
        selected: selected,
        onSelected: (_) => onTap(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing, size: 18),
            ],
          ],
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          chip(
            label: 'Este Mês',
            selected: state.thisMonth,
            onTap: controller.toggleThisMonth,
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (chipContext) => chip(
              label: _typeLabels[state.type]!,
              selected: state.type != null,
              trailing: Icons.arrow_drop_down,
              onTap: () async {
                final box = chipContext.findRenderObject()! as RenderBox;
                final origin = box.localToGlobal(Offset(0, box.size.height));
                final picked = await showMenu<_TypeChoice>(
                  context: chipContext,
                  position: RelativeRect.fromLTRB(
                    origin.dx,
                    origin.dy,
                    origin.dx,
                    0,
                  ),
                  items: [
                    for (final MapEntry(key: type, value: label)
                        in _typeLabels.entries)
                      PopupMenuItem(
                        value: _TypeChoice(type),
                        child: Text(label),
                      ),
                  ],
                );
                if (picked != null) controller.setType(picked.type);
              },
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (chipContext) => chip(
              label:
                  state.categories[state.categoryId]?.name ??
                  'Todas as Categorias',
              selected: state.categoryId != null,
              trailing: Icons.arrow_drop_down,
              onTap: () async {
                final box = chipContext.findRenderObject()! as RenderBox;
                final origin = box.localToGlobal(Offset(0, box.size.height));
                final picked = await showMenu<_CategoryChoice>(
                  context: chipContext,
                  position: RelativeRect.fromLTRB(
                    origin.dx,
                    origin.dy,
                    origin.dx,
                    0,
                  ),
                  items: [
                    const PopupMenuItem(
                      value: _CategoryChoice(null),
                      child: Text('Todas as Categorias'),
                    ),
                    for (final category in state.categories.values)
                      PopupMenuItem(
                        value: _CategoryChoice(category.id),
                        child: Text(category.name),
                      ),
                  ],
                );
                if (picked != null) controller.setCategory(picked.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps the nullable type so "all types" is distinguishable from dismissal.
class _TypeChoice {
  const _TypeChoice(this.type);

  final TransactionType? type;
}

/// Wraps the nullable category id so "all categories" is distinguishable
/// from dismissal.
class _CategoryChoice {
  const _CategoryChoice(this.id);

  final int? id;
}
