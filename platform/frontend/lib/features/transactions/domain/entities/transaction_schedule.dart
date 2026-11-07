import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';

@immutable
class TransactionSchedule {
  const TransactionSchedule({
    required this.totalAmount,
    this.installmentsCount = 1,
  });

  final Money totalAmount;
  final int installmentsCount;

  bool get isRecurring => installmentsCount > 1;

  @override
  bool operator ==(Object other) =>
      other is TransactionSchedule &&
      other.totalAmount == totalAmount &&
      other.installmentsCount == installmentsCount;

  @override
  int get hashCode => Object.hash(totalAmount, installmentsCount);
}
