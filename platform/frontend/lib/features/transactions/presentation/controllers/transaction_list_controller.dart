import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clock.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_type.dart';
import 'transaction_list_state.dart';

final transactionListControllerProvider =
    NotifierProvider.autoDispose<
      TransactionListController,
      TransactionListState
    >(TransactionListController.new);

/// Statement ("Transações" tab): filters, first page and infinite scroll.
class TransactionListController extends Notifier<TransactionListState> {
  static const perPage = 20;

  /// Bumped on every reload so a slow response for old filters is dropped.
  int _generation = 0;

  @override
  TransactionListState build() {
    Future.microtask(refresh);
    return const TransactionListState(loading: true);
  }

  TransactionFilter get _filter {
    if (!state.thisMonth) {
      return TransactionFilter(type: state.type, categoryId: state.categoryId);
    }
    final now = ref.read(clockProvider)();
    // GAP: the backend lists a transaction only when all its installments
    // fall in the range, so splits spanning other months are left out.
    return TransactionFilter(
      type: state.type,
      categoryId: state.categoryId,
      dateFrom: DateTime(now.year, now.month),
      dateTo: DateTime(now.year, now.month + 1, 0),
    );
  }

  /// Reloads the first page (and the categories used by the rows).
  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(loading: true, error: () => null);
    try {
      final (page, categories) = await (
        ref
            .read(transactionRepositoryProvider)
            .list(filter: _filter, perPage: perPage),
        ref.read(categoryRepositoryProvider).list(),
      ).wait;
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        items: page.items,
        categories: {for (final c in categories) c.id: c},
        page: page.currentPage,
        hasMore: page.hasMore,
        loading: false,
        loadingMore: false,
      );
    } on ParallelWaitError<dynamic, dynamic> catch (e) {
      _failed(generation, _firstFailure(e));
    } on Failure catch (failure) {
      _failed(generation, failure);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(transactionRepositoryProvider)
          .list(filter: _filter, page: state.page + 1, perPage: perPage);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: page.currentPage,
        hasMore: page.hasMore,
        loadingMore: false,
      );
    } on Failure {
      // Keep what is on screen; scrolling again retries.
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loadingMore: false);
    }
  }

  void toggleThisMonth() {
    state = state.copyWith(thisMonth: !state.thisMonth);
    refresh();
  }

  void setType(TransactionType? type) {
    if (type == state.type) return;
    state = state.copyWith(type: () => type);
    refresh();
  }

  void setCategory(int? categoryId) {
    if (categoryId == state.categoryId) return;
    state = state.copyWith(categoryId: () => categoryId);
    refresh();
  }

  void setSearch(String text) {
    state = state.copyWith(search: text);
  }

  void _failed(int generation, Failure failure) {
    if (!ref.mounted || generation != _generation) return;
    state = state.copyWith(
      loading: false,
      loadingMore: false,
      error: () => ErrorMessages.general(failure),
    );
  }

  static Failure _firstFailure(ParallelWaitError<dynamic, dynamic> error) {
    final errors = error.errors as (AsyncError?, AsyncError?);
    final first = errors.$1?.error ?? errors.$2?.error;
    return first is Failure ? first : const UnexpectedFailure();
  }
}
