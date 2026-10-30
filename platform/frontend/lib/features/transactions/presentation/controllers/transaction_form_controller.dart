import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../goals/data/repositories/goal_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/recurring_input.dart';
import '../../domain/entities/transaction_input.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/transaction_update.dart';
import 'transaction_form_state.dart';

/// Keyed by the transaction id; null is "Nova Transação".
final transactionFormControllerProvider = NotifierProvider.autoDispose
    .family<TransactionFormController, TransactionFormState, int?>(
      TransactionFormController.new,
    );

/// "Nova Transação" and "Editar Transação" (plus delete and ending a
/// recurrence, which have no screen of their own in the design).
class TransactionFormController extends Notifier<TransactionFormState> {
  TransactionFormController(this.transactionId);

  final int? transactionId;

  /// Backend fields that have a place on screen. `amount`/`start_date` come
  /// from `/recurring-transactions` and are shown under the value and date.
  static const _fields = [
    'total_amount',
    'amount',
    'description',
    'date',
    'start_date',
    'category_id',
    'goal_id',
    'installments_count',
    'period_unit',
    'end_date',
    'occurrences',
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
      if (original?.type == TransactionType.transfer) await loadGoals();
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        loadError: () => ErrorMessages.general(failure),
      );
    }
  }

  /// The goals a transfer can go to. Loaded on demand: only transfers need
  /// them.
  Future<void> loadGoals() async {
    if (state.goalsLoading) return;
    state = state.copyWith(goalsLoading: true, goalsError: () => null);
    try {
      final goals = await ref.read(goalRepositoryProvider).list();
      if (!ref.mounted) return;
      state = state.copyWith(goalsLoading: false, goals: goals);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        goalsLoading: false,
        goalsError: () => ErrorMessages.general(failure),
      );
    }
  }

  /// A category created from the "Criar Categoria" chip.
  void categoryCreated(Category category) {
    state = state.copyWith(categories: [...state.categories, category]);
  }

  Future<void> save(TransactionInput draft) => _run(() async {
    final repository = ref.read(transactionRepositoryProvider);
    final original = state.original;
    if (original == null) {
      await repository.create(draft);
      return;
    }
    final isTransfer = original.type == TransactionType.transfer;
    final scheduleChanged =
        draft.schedule.totalAmount != original.totalAmount ||
        draft.schedule.installmentsCount != original.installmentsCount;
    await repository.update(
      original.id,
      TransactionUpdate(
        categoryId: isTransfer ? null : draft.categoryId,
        goalId: isTransfer ? draft.goalId : null,
        description: draft.description,
        date: draft.date,
        schedule: scheduleChanged ? draft.schedule : null,
      ),
    );
  });

  /// "Transação Recorrente" on a new transaction.
  Future<void> saveRecurring(RecurringInput draft) => _run(
    () => ref.read(transactionRepositoryProvider).createRecurring(draft),
  );

  /// "Cancelar Transação Recorrente": stops future occurrences; this and the
  /// earlier transactions stay.
  Future<void> endRecurrence() async {
    final recurringId = state.original?.recurringTransactionId;
    if (recurringId == null || state.busy) return;
    state = state.copyWith(endingRecurrence: true, formError: () => null);
    try {
      await ref.read(transactionRepositoryProvider).endRecurring(recurringId);
      if (!ref.mounted) return;
      state = state.copyWith(endingRecurrence: false, recurrenceEnded: true);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        endingRecurrence: false,
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

  /// Runs a save, mapping the API's 422 onto the fields on screen.
  Future<void> _run(Future<void> Function() request) async {
    if (state.busy) return;
    state = state.copyWith(
      saving: true,
      fieldErrors: const {},
      formError: () => null,
    );
    try {
      await request();
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
}
