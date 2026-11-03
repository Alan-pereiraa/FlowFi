import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clock.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/errors/ledger_error_messages.dart';
import '../../data/repositories/category_repository_impl.dart';
import 'categories_list_state.dart';

final categoriesListControllerProvider =
    NotifierProvider.autoDispose<CategoriesListController, CategoriesListState>(
      CategoriesListController.new,
    );

/// Loads the caller's categories and this month's spending in each; also used
/// for pull-to-refresh and "retry".
class CategoriesListController extends Notifier<CategoriesListState> {
  @override
  CategoriesListState build() {
    Future.microtask(load);
    return const CategoriesListState(loading: true);
  }

  Future<void> load() async {
    // Keep what is already on screen while a refresh is in flight.
    state = CategoriesListState(
      loading: true,
      loaded: state.loaded,
      categories: state.categories,
      spentCents: state.spentCents,
    );
    final repository = ref.read(categoryRepositoryProvider);
    final spending = _loadSpending();
    try {
      final categories = await repository.list();
      final spent = await spending;
      if (!ref.mounted) return;
      state = CategoriesListState(
        loaded: true,
        categories: categories,
        spentCents: spent,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = CategoriesListState(
        loaded: state.loaded,
        categories: state.categories,
        spentCents: state.spentCents,
        errorMessage: LedgerErrorMessages.general(failure),
      );
    }
  }

  /// Spending is extra: if it fails the list still shows, with limits only.
  Future<Map<int, int>?> _loadSpending() async {
    try {
      return await ref
          .read(categoryRepositoryProvider)
          .spentInMonth(ref.read(clockProvider)());
    } on Failure {
      return null;
    }
  }
}
