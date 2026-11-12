import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../core/clock.dart';
import '../../../../shared/utils/dates.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/installment.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import '../controllers/transaction_list_controller.dart';
import '../controllers/transaction_list_state.dart';
import '../widgets/transaction_tile.dart';

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

  Future<void> _openForm(String location) async {
    await context.push<bool>(location);
    if (!mounted) return;
    await ref.read(transactionListControllerProvider.notifier).refresh();
  }

  Future<void> _pay(Transaction item, Installment installment) async {
    final controller = ref.read(transactionListControllerProvider.notifier);
    final error = await controller.payInstallment(item, installment);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Parcela paga.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            final undoError = await controller.unpayInstallment(
              item,
              installment,
            );
            if (undoError != null) {
              messenger.showSnackBar(SnackBar(content: Text(undoError)));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions-new-transaction',
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
    final byDay = state.byDay;
    if (state.overdueOnly && byDay.isEmpty && state.search.trim().isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Nenhuma parcela vencida',
            message: 'Nada em atraso com os filtros selecionados.',
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
    if (byDay.isEmpty &&
        state.search.trim().isNotEmpty &&
        (state.hasMore || state.loadingMore)) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (byDay.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: 'Nada encontrado',
            message: 'Nenhuma transação combina com a busca.',
          ),
        ),
      ];
    }

    final today = ref.read(clockProvider)();
    return [
      for (final (day, items) in byDay)
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
              for (final entry in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransactionTile(
                    transaction: entry.transaction,
                    installment: entry.installment,
                    category: state.categories[entry.transaction.categoryId],
                    onTap: () =>
                        _openForm(Routes.editTransaction(entry.transaction.id)),
                    onPay: entry.installment == null
                        ? null
                        : () => _pay(entry.transaction, entry.installment!),
                    paying:
                        entry.installment != null &&
                        state.payingId == entry.installment!.id,
                    today: today,
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
    TransactionType.withdrawal: 'Resgates',
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
          chip(
            label: 'Vencidas',
            selected: state.overdueOnly,
            onTap: controller.toggleOverdueOnly,
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
              label: state.uncategorized
                  ? 'Sem categoria'
                  : state.categories[state.categoryId]?.name ??
                        'Todas as Categorias',
              selected: state.categoryId != null || state.uncategorized,
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
                    const PopupMenuItem(
                      value: _CategoryChoice(null, uncategorized: true),
                      child: Text('Sem categoria'),
                    ),
                    for (final category in state.categories.values)
                      PopupMenuItem(
                        value: _CategoryChoice(category.id),
                        child: Text(category.name),
                      ),
                  ],
                );
                if (picked != null) {
                  controller.setCategory(
                    picked.id,
                    uncategorized: picked.uncategorized,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChoice {
  const _TypeChoice(this.type);

  final TransactionType? type;
}

class _CategoryChoice {
  const _CategoryChoice(this.id, {this.uncategorized = false});

  final int? id;

  final bool uncategorized;
}
