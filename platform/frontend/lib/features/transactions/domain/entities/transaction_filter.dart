import 'package:flutter/foundation.dart';

import 'transaction_type.dart';

/// Query filters of `GET /transactions`.
@immutable
class TransactionFilter {
  const TransactionFilter({this.type, this.dateFrom, this.dateTo});

  final TransactionType? type;

  /// The backend matches the range against the installments: a transaction
  /// is listed only when all of them fall inside it.
  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.type == type &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo;

  @override
  int get hashCode => Object.hash(type, dateFrom, dateTo);
}
