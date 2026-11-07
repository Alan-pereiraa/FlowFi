import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../goals/data/repositories/goal_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/installment.dart';
import '../../domain/entities/recurring_input.dart';
import '../../domain/entities/transaction_input.dart';
import '../../domain/entities/transaction_update.dart';
import 'transaction_form_state.dart';
import '../../domain/entities/recurrence.dart';

final transactionFormControllerProvider = NotifierProvider.autoDispose
    .family<TransactionFormController, TransactionFormState, int?>(
      TransactionFormController.new,
    );

class TransactionFormController extends Notifier<TransactionFormState> {
  TransactionFormController(this.transactionId);

  final int? transactionId;

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
      final recurringId = original?.recurringTransactionId;
      final (recurrence, recurrenceActive) = recurringId == null
          ? (null, false)
          : await _loadRecurrence(recurringId);
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        original: original,
        categories: categories,
        recurrenceActive: recurrenceActive,
        recurrence: () => recurrence,
      );
      if (original?.type.movesGoal ?? false) await loadGoals();
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        loadError: () => ErrorMessages.general(failure),
      );
    }
  }

  Future<(Recurrence?, bool)> _loadRecurrence(int recurringId) async {
    try {
      final recurrence = await ref
          .read(transactionRepositoryProvider)
          .recurrence(recurringId);
      return (recurrence, recurrence.active);
    } on NotFoundFailure {
      return (null, false);
    } on Failure {
      return (null, true);
    }
  }

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
    final movesGoal = original.type.movesGoal;
    final scheduleChanged =
        draft.schedule.totalAmount != original.totalAmount ||
        draft.schedule.installmentsCount != original.installmentsCount;
    await repository.update(
      original.id,
      TransactionUpdate(
        categoryId: movesGoal ? null : draft.categoryId,
        goalId: movesGoal ? draft.goalId : null,
        description: draft.description,
        date: draft.date,
        schedule: scheduleChanged ? draft.schedule : null,
      ),
    );
  });

  Future<void> saveRecurring(RecurringInput draft) => _run(
    () => ref.read(transactionRepositoryProvider).createRecurring(draft),
  );

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

  Future<void> toggleInstallment(Installment installment) async {
    final original = state.original;
    if (original == null || state.busy) return;
    state = state.copyWith(
      updatingInstallmentId: () => installment.id,
      formError: () => null,
    );
    final repository = ref.read(transactionRepositoryProvider);
    try {
      final updated = installment.isPaid
          ? await repository.unpayInstallment(original.id, installment.id)
          : await repository.payInstallment(original.id, installment.id);
      if (!ref.mounted) return;
      state = state.copyWith(
        updatingInstallmentId: () => null,
        original: original.withInstallment(updated),
      );
      ref.invalidate(dashboardControllerProvider);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        updatingInstallmentId: () => null,
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
      final formError = fieldErrors.isEmpty
          ? ErrorMessages.general(failure)
          : null;
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
