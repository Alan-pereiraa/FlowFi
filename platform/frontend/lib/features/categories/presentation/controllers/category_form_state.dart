import 'package:flutter/foundation.dart' show immutable;

import '../../domain/entities/category.dart';

/// How the form ended; the page reacts by showing a message and leaving.
enum CategoryOutcome { created, updated, removed }

@immutable
class CategoryFormState {
  const CategoryFormState({
    this.loadingInitial = false,
    this.initial,
    this.loadError,
    this.saving = false,
    this.removing = false,
    this.outcome,
    this.fieldErrors = const {},
    this.formError,
  });

  /// Edit by id with nothing handed over: the category is being fetched.
  final bool loadingInitial;

  /// The fetched category, for that same case.
  final Category? initial;
  final String? loadError;

  final bool saving;
  final bool removing;
  final CategoryOutcome? outcome;

  /// pt-BR messages keyed by backend field name.
  final Map<String, String> fieldErrors;
  final String? formError;

  bool get busy => saving || removing;

  CategoryFormState copyWith({
    bool? loadingInitial,
    Category? initial,
    String? Function()? loadError,
    bool? saving,
    bool? removing,
    CategoryOutcome? Function()? outcome,
    Map<String, String>? fieldErrors,
    String? Function()? formError,
  }) {
    return CategoryFormState(
      loadingInitial: loadingInitial ?? this.loadingInitial,
      initial: initial ?? this.initial,
      loadError: loadError == null ? this.loadError : loadError(),
      saving: saving ?? this.saving,
      removing: removing ?? this.removing,
      outcome: outcome == null ? this.outcome : outcome(),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      formError: formError == null ? this.formError : formError(),
    );
  }
}
