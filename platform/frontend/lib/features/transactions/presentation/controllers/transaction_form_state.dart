import 'package:flutter/foundation.dart' show immutable;

import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';

@immutable
class TransactionFormState {
  const TransactionFormState({
    this.loading = false,
    this.loadError,
    this.original,
    this.categories = const [],
    this.saving = false,
    this.deleting = false,
    this.saved = false,
    this.deleted = false,
    this.fieldErrors = const {},
    this.formError,
  });

  /// Loading categories (and the transaction, when editing).
  final bool loading;
  final String? loadError;

  /// The transaction being edited; null on "Nova Transação".
  final Transaction? original;
  final List<Category> categories;

  final bool saving;
  final bool deleting;
  final bool saved;
  final bool deleted;

  /// pt-BR messages keyed by backend field name.
  final Map<String, String> fieldErrors;
  final String? formError;

  bool get busy => loading || saving || deleting;

  /// Amount, recurrence and duration are frozen once an installment is paid.
  bool get scheduleLocked => original?.hasPaidInstallment ?? false;

  TransactionFormState copyWith({
    bool? loading,
    String? Function()? loadError,
    Transaction? original,
    List<Category>? categories,
    bool? saving,
    bool? deleting,
    bool? saved,
    bool? deleted,
    Map<String, String>? fieldErrors,
    String? Function()? formError,
  }) {
    return TransactionFormState(
      loading: loading ?? this.loading,
      loadError: loadError == null ? this.loadError : loadError(),
      original: original ?? this.original,
      categories: categories ?? this.categories,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      saved: saved ?? this.saved,
      deleted: deleted ?? this.deleted,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: formError == null ? this.formError : formError(),
    );
  }
}
