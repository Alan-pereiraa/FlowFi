import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';

@immutable
class MoneyFlow {
  const MoneyFlow({
    required this.paid,
    required this.pending,
    required this.total,
  });

  static const zero = MoneyFlow(
    paid: Money.zero,
    pending: Money.zero,
    total: Money.zero,
  );

  final Money paid;
  final Money pending;
  final Money total;

  @override
  bool operator ==(Object other) =>
      other is MoneyFlow &&
      other.paid == paid &&
      other.pending == pending &&
      other.total == total;

  @override
  int get hashCode => Object.hash(paid, pending, total);
}
