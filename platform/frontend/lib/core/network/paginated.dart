import 'package:flutter/foundation.dart';

/// One page of a Laravel paginator response (`data`, `meta`, `links`).
@immutable
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) parseItem,
  ) {
    final meta = json['meta'] as Map<String, dynamic>;
    return Paginated(
      items: (json['data'] as List<dynamic>)
          .map((item) => parseItem(item as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
      total: meta['total'] as int,
    );
  }

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  Paginated<R> map<R>(R Function(T item) convert) => Paginated(
    items: items.map(convert).toList(),
    currentPage: currentPage,
    lastPage: lastPage,
    total: total,
  );
}
