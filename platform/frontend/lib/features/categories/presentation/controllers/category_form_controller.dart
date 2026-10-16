import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category_input.dart';
import 'category_form_state.dart';

final categoryFormControllerProvider =
    NotifierProvider.autoDispose<CategoryFormController, CategoryFormState>(
      CategoryFormController.new,
    );

/// "Adicionar Categoria".
class CategoryFormController extends Notifier<CategoryFormState> {
  static const _fields = ['name', 'icon', 'color', 'limit_amount'];

  @override
  CategoryFormState build() => const CategoryFormState();

  Future<void> save(CategoryInput input) async {
    if (state.saving) return;
    state = const CategoryFormState(saving: true);
    try {
      final category = await ref.read(categoryRepositoryProvider).create(input);
      if (!ref.mounted) return;
      state = CategoryFormState(created: category);
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return;
      final fieldErrors = {
        for (final field in _fields)
          field: ?ErrorMessages.forField(failure, field),
      };
      state = CategoryFormState(
        fieldErrors: fieldErrors,
        formError: fieldErrors.isEmpty ? ErrorMessages.general(failure) : null,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = CategoryFormState(formError: ErrorMessages.general(failure));
    }
  }
}
