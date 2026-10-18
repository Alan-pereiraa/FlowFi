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

  /// First page (or a refresh after a filter change).
  final bool loading;
  final bool loadingMore;
  final bool hasMore;

  /// Last page loaded; 0 before the first load.
  final int page;

  /// pt-BR message when the first page failed.
  final String? error;

  /// Items grouped by transaction date, keeping the API's newest-first order.
  List<(DateTime, List<Transaction>)> get byDay {
    final groups = <(DateTime, List<Transaction>)>[];
    for (final item in items) {
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
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error == null ? this.error : error(),
    );
  }
}
