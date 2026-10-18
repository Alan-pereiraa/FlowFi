import 'package:flutter/foundation.dart' show immutable;

import '../../domain/entities/category.dart';

@immutable
class CategoriesListState {
  const CategoriesListState({
    this.loading = false,
    this.loaded = false,
    this.categories = const <Category>[],
    this.errorMessage,
  });

  /// A request is in flight (first load or a refresh).
  final bool loading;

  /// At least one load has succeeded, so [categories] is real data.
  final bool loaded;
  final List<Category> categories;

  /// pt-BR message of the last failed load; null after a success.
  final String? errorMessage;

  /// Full-screen spinner: nothing to show yet.
  bool get showSpinner => loading && !loaded;

  /// Full-screen error: nothing to show and the load failed.
  bool get showError => !loaded && !loading && errorMessage != null;
}
