import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clock.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/installment.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_type.dart';
import 'transaction_list_state.dart';

final transactionListControllerProvider =
    NotifierProvider.autoDispose<
      TransactionListController,
      TransactionListState
    >(TransactionListController.new);

class TransactionListController extends Notifier<TransactionListState> {
  static const perPage = 20;

  int _generation = 0;

  @override
  TransactionListState build() {
    Future.microtask(refresh);
    return const TransactionListState(loading: true);
  }

  TransactionFilter get _filter {
    final now = ref.read(clockProvider)();
    return TransactionFilter(
      type: state.type,
      categoryId: state.categoryId,
      uncategorized: state.uncategorized,
      dateFrom: state.thisMonth ? DateTime(now.year, now.month) : null,
      dateTo: state.thisMonth ? DateTime(now.year, now.month + 1, 0) : null,
      overdue: state.overdueOnly,
    );
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final now = ref.read(clockProvider)();
    state = state.copyWith(
      loading: true,
      error: () => null,
      month: () => state.thisMonth ? DateTime(now.year, now.month) : null,
      overdueOn: () => state.overdueOnly ? now : null,
    );
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
      _keepLoadingWhileSearching();
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
      _keepLoadingWhileSearching();
    } on Failure {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loadingMore: false);
    }
  }

  Future<String?> payInstallment(
    Transaction transaction,
    Installment installment,
  ) => _setInstallmentPaid(transaction, installment, paid: true);

  Future<String?> unpayInstallment(
    Transaction transaction,
    Installment installment,
  ) => _setInstallmentPaid(transaction, installment, paid: false);

  Future<String?> _setInstallmentPaid(
    Transaction transaction,
    Installment installment, {
    required bool paid,
  }) async {
    if (state.payingId != null) return null;
    state = state.copyWith(payingId: () => installment.id);
    try {
      final repository = ref.read(transactionRepositoryProvider);
      final updated = paid
          ? await repository.payInstallment(transaction.id, installment.id)
          : await repository.unpayInstallment(transaction.id, installment.id);
      if (!ref.mounted) return null;
      state = state.copyWith(
        payingId: () => null,
        items: [
          for (final item in state.items)
            item.id == transaction.id ? item.withInstallment(updated) : item,
        ],
      );
      ref.invalidate(dashboardControllerProvider);
      return null;
    } on Failure catch (failure) {
      if (!ref.mounted) return null;
      state = state.copyWith(payingId: () => null);
      return ErrorMessages.general(failure);
    }
  }

  void toggleThisMonth() {
    state = state.copyWith(thisMonth: !state.thisMonth);
    refresh();
  }

  void toggleOverdueOnly() {
    final overdueOnly = !state.overdueOnly;
    state = state.copyWith(
      overdueOnly: overdueOnly,
      thisMonth: overdueOnly ? false : state.thisMonth,
    );
    refresh();
  }

  void setType(TransactionType? type) {
    if (type == state.type) return;
    state = state.copyWith(type: () => type);
    refresh();
  }

  void setCategory(int? categoryId, {bool uncategorized = false}) {
    if (categoryId == state.categoryId &&
        uncategorized == state.uncategorized) {
      return;
    }
    state = state.copyWith(
      categoryId: () => uncategorized ? null : categoryId,
      uncategorized: uncategorized,
    );
    refresh();
  }

  void setSearch(String text) {
    state = state.copyWith(search: text);
    _keepLoadingWhileSearching();
  }

  void _keepLoadingWhileSearching() {
    if (state.search.trim().isEmpty || !state.hasMore) return;
    Future.microtask(loadMore);
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
