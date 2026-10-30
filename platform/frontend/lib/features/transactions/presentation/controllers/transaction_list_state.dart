import 'package:flutter/foundation.dart' show immutable;

import '../../../../shared/utils/dates.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';

@immutable
class TransactionListState {
  const TransactionListState({
    this.items = const [],
    this.categories = const {},
    this.thisMonth = true,
    this.type,
    this.categoryId,
    this.search = '',
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.error,
  });

  final List<Transaction> items;

  /// For each row's icon, color and name.
  final Map<int, Category> categories;

  /// "Este Mês" chip.
  final bool thisMonth;

  /// "Todos os Tipos" chip; null = all.
  final TransactionType? type;

  /// "Todas as Categorias" chip; null = all.
  final int? categoryId;

  /// Search box text. Matched on the client against what is loaded (the API
  /// has no text search).
  final String search;

  /// First page (or a refresh after a filter change).
  final bool loading;
  final bool loadingMore;
  final bool hasMore;

  /// Last page loaded; 0 before the first load.
  final int page;

  /// pt-BR message when the first page failed.
  final String? error;

  /// [items] narrowed by [search] (description or category name, ignoring
  /// case and accents).
  List<Transaction> get visibleItems {
    final query = _fold(search.trim());
    if (query.isEmpty) return items;
    return [
      for (final item in items)
        if (_fold(item.description ?? '').contains(query) ||
            _fold(categories[item.categoryId]?.name ?? '').contains(query))
          item,
    ];
  }

  /// [visibleItems] grouped by transaction date, keeping the API's
  /// newest-first order.
  List<(DateTime, List<Transaction>)> get byDay {
    final groups = <(DateTime, List<Transaction>)>[];
    for (final item in visibleItems) {
      final day = Dates.dateOnly(item.date);
      if (groups.isEmpty || groups.last.$1 != day) groups.add((day, []));
      groups.last.$2.add(item);
    }
    return groups;
  }

  TransactionListState copyWith({
    List<Transaction>? items,
    Map<int, Category>? categories,
    bool? thisMonth,
    TransactionType? Function()? type,
    int? Function()? categoryId,
    String? search,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? Function()? error,
  }) {
    return TransactionListState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      thisMonth: thisMonth ?? this.thisMonth,
      type: type == null ? this.type : type(),
      categoryId: categoryId == null ? this.categoryId : categoryId(),
      search: search ?? this.search,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error == null ? this.error : error(),
    );
  }

  static const _accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  static String _fold(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }
}
