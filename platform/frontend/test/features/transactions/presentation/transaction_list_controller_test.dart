import 'package:flowfi_app/core/clock.dart';
import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/paginated.dart';
import 'package:flowfi_app/features/categories/data/models/category_dto.dart';
import 'package:flowfi_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:flowfi_app/features/categories/domain/repositories/category_repository.dart';
import 'package:flowfi_app/features/transactions/data/models/transaction_dto.dart';
import 'package:flowfi_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flowfi_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flowfi_app/features/transactions/presentation/controllers/transaction_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class _MockTransactions extends Mock implements TransactionRepository {}

class _MockCategories extends Mock implements CategoryRepository {}

Transaction _tx(int id, String date) =>
    TransactionDto.fromJson(transactionJson(id: id, date: date)).toEntity();

Paginated<Transaction> _page(
  List<Transaction> items, {
  int current = 1,
  int last = 1,
}) => Paginated(
  items: items,
  currentPage: current,
  lastPage: last,
  total: items.length,
);

void main() {
  late _MockTransactions transactions;
  late _MockCategories categories;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    transactions = _MockTransactions();
    categories = _MockCategories();
    when(() => categories.list()).thenAnswer(
      (_) async => [CategoryDto.fromJson(categoryJson()).toEntity()],
    );
  });

  ProviderContainer makeContainer() => ProviderContainer.test(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(transactions),
      categoryRepositoryProvider.overrideWithValue(categories),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 24, 12)),
    ],
  );

  Future<ProviderContainer> boot() async {
    final container = makeContainer();
    container.listen(transactionListControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  test('first load filters the current month and groups by day', () async {
    when(
      () => transactions.list(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => _page([
        _tx(3, '2026-10-24'),
        _tx(2, '2026-10-24'),
        _tx(1, '2026-10-23'),
      ]),
    );

    final container = await boot();
    final state = container.read(transactionListControllerProvider);

    final filter =
        verify(
              () => transactions.list(
                filter: captureAny(named: 'filter'),
                page: any(named: 'page'),
                perPage: 20,
              ),
            ).captured.single
            as TransactionFilter;
    expect(filter.dateFrom, DateTime(2026, 10));
    expect(filter.dateTo, DateTime(2026, 10, 31));
    expect(state.loading, isFalse);
    expect(state.categories.keys, [3]);
    expect(state.byDay.map((g) => (g.$1, g.$2.length)), [
      (DateTime(2026, 10, 24), 2),
      (DateTime(2026, 10, 23), 1),
    ]);
  });

  test('type filter and "Este Mês" off reload without a date range', () async {
    when(
      () => transactions.list(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => _page([]));

    final container = await boot();
    final controller = container.read(
      transactionListControllerProvider.notifier,
    );
    controller.toggleThisMonth();
    controller.setType(TransactionType.income);
    await pumpEventQueue();

    final last =
        verify(
              () => transactions.list(
                filter: captureAny(named: 'filter'),
                page: any(named: 'page'),
                perPage: any(named: 'perPage'),
              ),
            ).captured.last
            as TransactionFilter;
    expect(last, const TransactionFilter(type: TransactionType.income));
  });

  test('loadMore appends the next page', () async {
    when(
      () => transactions.list(
        filter: any(named: 'filter'),
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => _page([_tx(2, '2026-10-24')], last: 2));
    when(
      () => transactions.list(
        filter: any(named: 'filter'),
        page: 2,
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => _page([_tx(1, '2026-10-20')], current: 2, last: 2),
    );

    final container = await boot();
    await container.read(transactionListControllerProvider.notifier).loadMore();
    final state = container.read(transactionListControllerProvider);

    expect(state.items.map((t) => t.id), [2, 1]);
    expect(state.hasMore, isFalse);
  });

  test('a failed first load shows a pt-BR error', () async {
    when(
      () => transactions.list(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(const NetworkFailure());

    final container = await boot();
    final state = container.read(transactionListControllerProvider);

    expect(state.loading, isFalse);
    expect(state.error, contains('Sem conexão'));
  });
}
