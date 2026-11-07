import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clock.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/error_messages.dart';
import '../../data/repositories/category_repository_impl.dart';
import 'categories_list_state.dart';

final categoriesListControllerProvider =
    NotifierProvider.autoDispose<CategoriesListController, CategoriesListState>(
      CategoriesListController.new,
    );

class CategoriesListController extends Notifier<CategoriesListState> {
  @override
  CategoriesListState build() {
    Future.microtask(load);
    return const CategoriesListState(loading: true);
  }

  Future<void> load() async {
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
        errorMessage: ErrorMessages.general(failure),
      );
    }
  }

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
