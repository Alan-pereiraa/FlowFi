import 'package:flutter/foundation.dart' show immutable;

import '../../../categories/domain/entities/category.dart';
import '../../../goals/domain/entities/goal.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/recurrence.dart';

@immutable
class CategoryLimitNotice {
  const CategoryLimitNotice({required this.message, this.categoryId});

  final String message;
  final int? categoryId;
}

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
    this.recurrenceActive = false,
    this.recurrence,
    this.updatingInstallmentId,
    this.saved = false,
    this.deleted = false,
    this.recurrenceEnded = false,
    this.fieldErrors = const {},
    this.formError,
    this.usedCents,
    this.usageMonth,
    this.limitNotice,
  });

  final bool loading;
  final String? loadError;

  final Transaction? original;
  final List<Category> categories;

  final List<Goal> goals;
  final bool goalsLoading;
  final String? goalsError;

  final bool saving;
  final bool deleting;
  final bool endingRecurrence;
  final bool recurrenceActive;

  final Recurrence? recurrence;
  final int? updatingInstallmentId;
  final bool saved;
  final bool deleted;
  final bool recurrenceEnded;

  final Map<String, String> fieldErrors;
  final String? formError;

  final Map<int, int>? usedCents;
  final DateTime? usageMonth;

  final CategoryLimitNotice? limitNotice;

  int? usedOf(int categoryId) =>
      usedCents == null ? null : (usedCents![categoryId] ?? 0);

  bool get busy =>
      loading ||
      saving ||
      deleting ||
      endingRecurrence ||
      updatingInstallmentId != null;

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
    bool? recurrenceActive,
    Recurrence? Function()? recurrence,
    int? Function()? updatingInstallmentId,
    bool? saved,
    bool? deleted,
    bool? recurrenceEnded,
    Map<String, String>? fieldErrors,
    String? Function()? formError,
    Map<int, int>? Function()? usedCents,
    DateTime? Function()? usageMonth,
    CategoryLimitNotice? Function()? limitNotice,
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
      recurrenceActive: recurrenceActive ?? this.recurrenceActive,
      recurrence: recurrence == null ? this.recurrence : recurrence(),
      updatingInstallmentId: updatingInstallmentId == null
          ? this.updatingInstallmentId
          : updatingInstallmentId(),
      saved: saved ?? this.saved,
      deleted: deleted ?? this.deleted,
      recurrenceEnded: recurrenceEnded ?? this.recurrenceEnded,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: formError == null ? this.formError : formError(),
      usedCents: usedCents == null ? this.usedCents : usedCents(),
      usageMonth: usageMonth == null ? this.usageMonth : usageMonth(),
      limitNotice: limitNotice == null ? this.limitNotice : limitNotice(),
    );
  }
}
