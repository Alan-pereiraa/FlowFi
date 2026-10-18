import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/errors/ledger_error_messages.dart';
import '../../data/repositories/category_repository_impl.dart';
import 'categories_list_state.dart';

final categoriesListControllerProvider =
    NotifierProvider.autoDispose<CategoriesListController, CategoriesListState>(
      CategoriesListController.new,
    );

/// Loads the caller's categories; also used for pull-to-refresh and "retry".
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
    );
    try {
      final categories = await ref.read(categoryRepositoryProvider).list();
      if (!ref.mounted) return;
      state = CategoriesListState(loaded: true, categories: categories);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = CategoriesListState(
        loaded: state.loaded,
        categories: state.categories,
        errorMessage: LedgerErrorMessages.general(failure),
      );
    }
  }
}
