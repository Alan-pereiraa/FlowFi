import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/errors/ledger_error_messages.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category_draft.dart';
import 'categories_list_controller.dart';
import 'category_form_state.dart';

final categoryFormControllerProvider =
    NotifierProvider.autoDispose<CategoryFormController, CategoryFormState>(
      CategoryFormController.new,
    );

/// Add, edit and remove a category from the same form.
class CategoryFormController extends Notifier<CategoryFormState> {
  static const _fields = ['name', 'icon', 'color', 'limit_amount'];

  @override
  CategoryFormState build() => const CategoryFormState();

  /// Fetches a category to edit when the screen was opened by id alone (a deep
  /// link or a browser refresh on web) and nothing was handed over.
  Future<void> loadForEdit(int id) async {
    state = state.copyWith(loadingInitial: true, loadError: () => null);
    try {
      final category = await ref.read(categoryRepositoryProvider).show(id);
      if (!ref.mounted) return;
      state = state.copyWith(loadingInitial: false, initial: category);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        loadingInitial: false,
        loadError: () => LedgerErrorMessages.general(failure),
      );
    }
  }

  Future<void> create(CategoryDraft data) => _save(
    () => ref.read(categoryRepositoryProvider).create(data),
    CategoryOutcome.created,
  );

  Future<void> update(int id, CategoryDraft data) => _save(
    () => ref.read(categoryRepositoryProvider).update(id, data),
    CategoryOutcome.updated,
  );

  Future<void> remove(int id) async {
    if (state.busy) return;
    state = state.copyWith(removing: true, formError: () => null);
    try {
      await ref.read(categoryRepositoryProvider).remove(id);
      if (!ref.mounted) return;
      state = state.copyWith(
        removing: false,
        outcome: () => CategoryOutcome.removed,
      );
      ref.invalidate(categoriesListControllerProvider);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        removing: false,
        formError: () => LedgerErrorMessages.general(failure),
      );
    }
  }

  Future<void> _save(
    Future<Object> Function() call,
    CategoryOutcome outcome,
  ) async {
    if (state.busy) return;
    state = state.copyWith(
      saving: true,
      fieldErrors: const {},
      formError: () => null,
    );
    try {
      await call();
      if (!ref.mounted) return;
      state = state.copyWith(saving: false, outcome: () => outcome);
      // The list behind this form is now stale.
      ref.invalidate(categoriesListControllerProvider);
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return;
      final fieldErrors = {
        for (final field in _fields)
          field: ?LedgerErrorMessages.categoryField(failure, field),
      };
      state = state.copyWith(
        saving: false,
        fieldErrors: fieldErrors,
        formError: () => fieldErrors.isEmpty
            ? LedgerErrorMessages.general(failure)
            : null,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        saving: false,
        formError: () => LedgerErrorMessages.general(failure),
      );
    }
  }
}
