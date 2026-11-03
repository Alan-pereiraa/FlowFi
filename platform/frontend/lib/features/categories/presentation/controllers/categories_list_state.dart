import 'package:flutter/foundation.dart' show immutable;

import '../../domain/entities/category.dart';

@immutable
class CategoriesListState {
  const CategoriesListState({
    this.loading = false,
    this.loaded = false,
    this.categories = const <Category>[],
    this.spentCents,
    this.errorMessage,
  });

  /// A request is in flight (first load or a refresh).
  final bool loading;

  /// At least one load has succeeded, so [categories] is real data.
  final bool loaded;
  final List<Category> categories;

  /// Cents spent this month by category id; null when it could not be loaded
  /// (the cards then show the limit only).
  final Map<int, int>? spentCents;

  /// pt-BR message of the last failed load; null after a success.
  final String? errorMessage;

  /// Full-screen spinner: nothing to show yet.
  bool get showSpinner => loading && !loaded;

  /// Full-screen error: nothing to show and the load failed.
  bool get showError => !loaded && !loading && errorMessage != null;

  /// This month's spending of [categoryId]: zero when it had no expense, null
  /// when spending is unknown.
  int? spentOf(int categoryId) =>
      spentCents == null ? null : (spentCents![categoryId] ?? 0);
}
