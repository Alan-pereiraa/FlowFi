import 'package:flutter/foundation.dart' show immutable;

import '../../../../shared/utils/dates.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/statement_entry.dart';
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
    this.uncategorized = false,
    this.search = '',
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.error,
    this.payingId,
    this.month,
    this.overdueOnly = false,
    this.overdueOn,
  });

  final List<Transaction> items;

  final Map<int, Category> categories;

  final bool thisMonth;

  final TransactionType? type;

  final int? categoryId;

  final bool uncategorized;

  final String search;

  final bool loading;
  final bool loadingMore;
  final bool hasMore;

  final int page;

  final String? error;

  final int? payingId;

  final DateTime? month;

  final bool overdueOnly;

  final DateTime? overdueOn;

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

  List<StatementEntry> get entries {
    final entries = <StatementEntry>[
      for (final item in visibleItems)
        if (item.installments.isEmpty && overdueOn == null)
          StatementEntry(transaction: item)
        else
          for (final installment in item.installments)
            if (_inMonth(installment.date) &&
                (overdueOn == null || installment.isOverdueOn(overdueOn!)))
              StatementEntry(transaction: item, installment: installment),
    ];
    entries.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      final byId = b.transaction.id.compareTo(a.transaction.id);
      if (byId != 0) return byId;
      return (b.installment?.step ?? 0).compareTo(a.installment?.step ?? 0);
    });
    return entries;
  }

  List<(DateTime, List<StatementEntry>)> get byDay {
    final groups = <(DateTime, List<StatementEntry>)>[];
    for (final entry in entries) {
      final day = Dates.dateOnly(entry.date);
      if (groups.isEmpty || groups.last.$1 != day) groups.add((day, []));
      groups.last.$2.add(entry);
    }
    return groups;
  }

  bool _inMonth(DateTime date) =>
      month == null || (date.year == month!.year && date.month == month!.month);

  TransactionListState copyWith({
    List<Transaction>? items,
    Map<int, Category>? categories,
    bool? thisMonth,
    TransactionType? Function()? type,
    int? Function()? categoryId,
    bool? uncategorized,
    String? search,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? Function()? error,
    int? Function()? payingId,
    DateTime? Function()? month,
    bool? overdueOnly,
    DateTime? Function()? overdueOn,
  }) {
    return TransactionListState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      thisMonth: thisMonth ?? this.thisMonth,
      type: type == null ? this.type : type(),
      categoryId: categoryId == null ? this.categoryId : categoryId(),
      uncategorized: uncategorized ?? this.uncategorized,
      search: search ?? this.search,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error == null ? this.error : error(),
      payingId: payingId == null ? this.payingId : payingId(),
      month: month == null ? this.month : month(),
      overdueOnly: overdueOnly ?? this.overdueOnly,
      overdueOn: overdueOn == null ? this.overdueOn : overdueOn(),
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
