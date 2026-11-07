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

  final bool loading;

  final bool loaded;
  final List<Category> categories;

  final Map<int, int>? spentCents;

  final String? errorMessage;

  bool get showSpinner => loading && !loaded;

  bool get showError => !loaded && !loading && errorMessage != null;

  int? spentOf(int categoryId) =>
      spentCents == null ? null : (spentCents![categoryId] ?? 0);
}
