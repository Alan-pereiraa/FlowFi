import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../categories/domain/entities/category.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction_input.dart';
import '../../domain/entities/transaction_update.dart';
import 'transaction_form_state.dart';

/// Keyed by the transaction id; null is "Nova Transação".
final transactionFormControllerProvider = NotifierProvider.autoDispose
    .family<TransactionFormController, TransactionFormState, int?>(
      TransactionFormController.new,
    );

/// "Nova Transação" and "Editar Transação" (plus delete, which has no screen
/// of its own in the design).
class TransactionFormController extends Notifier<TransactionFormState> {
  TransactionFormController(this.transactionId);

  final int? transactionId;

  static const _fields = [
    'total_amount',
    'description',
    'date',
    'category_id',
    'installments_count',
    'period_unit',
  ];

  bool get isEdit => transactionId != null;

  @override
  TransactionFormState build() {
    Future.microtask(load);
    return const TransactionFormState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, loadError: () => null);
    try {
      final original = isEdit
          ? await ref.read(transactionRepositoryProvider).show(transactionId!)
          : null;
      final categories = await ref.read(categoryRepositoryProvider).list();
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        original: original,
        categories: categories,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        loadError: () => ErrorMessages.general(failure),
      );
    }
  }

  /// A category created from the "Criar Categoria" chip.
  void categoryCreated(Category category) {
    state = state.copyWith(categories: [...state.categories, category]);
  }

  Future<void> save(TransactionInput draft) async {
    if (state.busy) return;
    state = state.copyWith(
      saving: true,
      fieldErrors: const {},
      formError: () => null,
    );
    final repository = ref.read(transactionRepositoryProvider);
    try {
      final original = state.original;
      if (original == null) {
        await repository.create(draft);
      } else {
        final scheduleChanged =
            draft.schedule.totalAmount != original.totalAmount ||
            draft.schedule.installmentsCount != original.installmentsCount;
        await repository.update(
          original.id,
          TransactionUpdate(
            categoryId: draft.categoryId,
            description: draft.description,
            date: draft.date,
            schedule: scheduleChanged ? draft.schedule : null,
          ),
        );
      }
      if (!ref.mounted) return;
      state = state.copyWith(saving: false, saved: true);
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return;
      final fieldErrors = {
        for (final field in _fields)
          field: ?ErrorMessages.forField(failure, field),
      };
      // The paid-installment lock comes on `installments`, which has no
      // field on screen.
      final formError =
          ErrorMessages.forField(failure, 'installments') ??
          (fieldErrors.isEmpty ? ErrorMessages.general(failure) : null);
      state = state.copyWith(
        saving: false,
        fieldErrors: fieldErrors,
        formError: () => formError,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        saving: false,
        formError: () => ErrorMessages.general(failure),
      );
    }
  }

  Future<void> delete() async {
    final original = state.original;
    if (original == null || state.busy) return;
    state = state.copyWith(deleting: true, formError: () => null);
    try {
      await ref.read(transactionRepositoryProvider).delete(original.id);
      if (!ref.mounted) return;
      state = state.copyWith(deleting: false, deleted: true);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        deleting: false,
        formError: () => ErrorMessages.general(failure),
      );
    }
  }
}
