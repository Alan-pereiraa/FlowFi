import 'package:flutter/foundation.dart' show immutable;

import '../../domain/entities/category.dart';

@immutable
class CategoryFormState {
  const CategoryFormState({
    this.saving = false,
    this.created,
    this.fieldErrors = const {},
    this.formError,
  });

  final bool saving;

  /// Set once the API accepted the category.
  final Category? created;

  /// pt-BR messages keyed by backend field name.
  final Map<String, String> fieldErrors;
  final String? formError;
}
