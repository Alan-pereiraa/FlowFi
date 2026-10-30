import 'package:flutter/foundation.dart' show immutable;

import '../../../categories/domain/entities/category.dart';
import '../../../goals/domain/entities/goal.dart';
import '../../domain/entities/transaction.dart';

@immutable
class TransactionFormState {
  const TransactionFormState({
    this.loading = false,
    this.loadError,
    this.original,
    this.categories = const [],
    this.goals = const [],
    this.goalsLoading = false,
    this.goalsError,
    this.saving = false,
    this.deleting = false,
    this.endingRecurrence = false,
    this.saved = false,
    this.deleted = false,
    this.recurrenceEnded = false,
    this.fieldErrors = const {},
    this.formError,
  });

  /// Loading categories (and the transaction, when editing).
  final bool loading;
  final String? loadError;

  /// The transaction being edited; null on "Nova Transação".
  final Transaction? original;
  final List<Category> categories;

  /// "Meta de destino" options, loaded the first time a transfer is shown.
  final List<Goal> goals;
  final bool goalsLoading;
  final String? goalsError;

  final bool saving;
  final bool deleting;
  final bool endingRecurrence;
  final bool saved;
  final bool deleted;
  final bool recurrenceEnded;

  /// pt-BR messages keyed by backend field name.
  final Map<String, String> fieldErrors;
  final String? formError;

  bool get busy => loading || saving || deleting || endingRecurrence;

  /// Amount, installments and duration are frozen once an installment is
  /// paid.
  bool get scheduleLocked => original?.hasPaidInstallment ?? false;

  TransactionFormState copyWith({
    bool? loading,
    String? Function()? loadError,
    Transaction? original,
    List<Category>? categories,
    List<Goal>? goals,
    bool? goalsLoading,
    String? Function()? goalsError,
    bool? saving,
    bool? deleting,
    bool? endingRecurrence,
    bool? saved,
    bool? deleted,
    bool? recurrenceEnded,
    Map<String, String>? fieldErrors,
    String? Function()? formError,
  }) {
    return TransactionFormState(
      loading: loading ?? this.loading,
      loadError: loadError == null ? this.loadError : loadError(),
      original: original ?? this.original,
      categories: categories ?? this.categories,
      goals: goals ?? this.goals,
      goalsLoading: goalsLoading ?? this.goalsLoading,
      goalsError: goalsError == null ? this.goalsError : goalsError(),
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      endingRecurrence: endingRecurrence ?? this.endingRecurrence,
      saved: saved ?? this.saved,
      deleted: deleted ?? this.deleted,
      recurrenceEnded: recurrenceEnded ?? this.recurrenceEnded,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: formError == null ? this.formError : formError(),
    );
  }
}
