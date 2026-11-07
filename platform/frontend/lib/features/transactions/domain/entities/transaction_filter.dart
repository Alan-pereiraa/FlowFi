import 'package:flutter/foundation.dart';

import 'transaction_type.dart';

@immutable
class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.categoryId,
    this.dateFrom,
    this.dateTo,
    this.overdue = false,
  });

  final TransactionType? type;

  final int? categoryId;

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool overdue;

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.overdue == overdue;

  @override
  int get hashCode => Object.hash(type, categoryId, dateFrom, dateTo, overdue);
}
